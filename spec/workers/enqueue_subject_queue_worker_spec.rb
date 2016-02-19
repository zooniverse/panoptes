require "spec_helper"
require 'subjects/cellect_session'

RSpec.describe EnqueueSubjectQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }
  let(:queue) do
    create(:subject_queue, workflow: workflow, user: user)
  end

  describe "#perform" do

    before(:each) do
      allow_any_instance_of(Subjects::PostgresqlSelection)
        .to receive(:select)
        .and_return((1..100).to_a)
    end

    it "should not raise an error if there is no queue" do
      expect { subject.perform(queue.id) }.not_to raise_error
    end

    it "should enqueue new data" do
      subject.perform(queue.id)
      expect(queue.reload.set_member_subject_ids.length).to eq(20)
    end

    context "when selecting via strategy param" do
      let(:result_ids) { [1] }

      it "should fallback from the override strategy" do
        allow_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select).and_return(result_ids)
        expect_any_instance_of(SubjectQueue).to receive(:enqueue_update)
        subject.perform(queue.id, nil, :unknown_strategy)
      end

      context "with cellect" do
        let(:run_selection) do
          subject.perform(queue.id, nil, :cellect)
        end
        before do
          allow(Panoptes).to receive(:cellect_on).and_return(true)
        end

        it "should use the cellect client" do
          expect(Subjects::CellectClient).to receive(:get_subjects)
            .and_return(result_ids)
          run_selection
        end

        it "should use a cellect session instance for session tracking" do
          stub_cellect_connection
          stub_redis_connection
          expect(Subjects::CellectSession).to receive(:new).and_call_original
          run_selection
        end

        it "should convert the cellect subject_ids to panoptes sms_ids" do
          allow(Subjects::CellectClient).to receive(:get_subjects)
            .and_return(result_ids)
          expect(SetMemberSubject).to receive(:by_subject_workflow)
            .with(result_ids, workflow.id).and_call_original
          run_selection
        end

        it "should attempt to queue the selected sms_id set", :aggregate_failures do
          selection_results = double(pluck: result_ids)
          allow(Subjects::CellectClient).to receive(:get_subjects)
            .and_return(result_ids)
          allow(SetMemberSubject).to receive(:by_subject_workflow)
            .and_return(selection_results)
          expect(selection_results).to receive(:pluck)
            .with("set_member_subjects.id")
          expect_any_instance_of(SubjectQueue).to receive(:enqueue_update)
          run_selection
        end

        context "when the cellect client can't reach a server" do
          it "should fall back to postgres strategy" do
            allow(Subjects::CellectClient).to receive(:get_subjects)
              .and_raise(Subjects::CellectClient::ConnectionError)
            expect_any_instance_of(Subjects::PostgresqlSelection)
              .to receive(:select)
            run_selection
          end
        end
      end
    end

    context "when subjects are selected" do
      before do
        allow_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select).and_return(result_ids)
      end

      context "when there are selected subjects to queue" do
        let(:result_ids) { [1] }

        it "should attempt to queue the selected set" do
          expect_any_instance_of(SubjectQueue).to receive(:enqueue_update)
          subject.perform(queue.id)
        end
      end

      context "when there are no selected subjects to queue" do
        let(:result_ids) { [] }

        it "should not attempt to queue an empty set" do
          expect_any_instance_of(SubjectQueue).not_to receive(:enqueue_update)
          subject.perform(queue.id)
        end
      end
    end
  end

  describe "#strategy" do
    let(:config) { { selection_strategy: :cellect } }
    let(:cellect_size) { Panoptes.cellect_min_pool_size }

    before do
      allow(subject).to receive(:workflow).and_return(workflow)
    end

    it "should fall back to postgresql strategy when not set" do
      expect(subject.strategy(nil)).to eq(nil)
    end

    context "when Cellect config is on" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(true)
      end

      it "should use the supplied strategy" do
        expect(subject.strategy(:cellect)).to eq(:cellect)
      end

      context "when the workflow config has a selection strategy" do
        it "should use the workflow config strategy" do
          allow(workflow).to receive(:configuration).and_return(config)
          expect(subject.strategy(nil)).to eq(:cellect)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should use the cellect strategy" do
          allow(workflow).to receive_message_chain("set_member_subjects.count") do
            cellect_size
          end
          expect(subject.strategy(nil)).to eq(:cellect)
        end
      end

      context "with a workflow config and large subject set size" do
        it "should only use the worfklow strategy", :aggregate_failures do
          allow(workflow).to receive(:configuration).and_return(config)
          allow(workflow).to receive_message_chain("set_member_subjects.count") do
            cellect_size
          end
          expect(workflow).not_to receive(:set_member_subjects)
          expect(subject.strategy(nil)).to eq(:cellect)
        end
      end
    end

    context "when Cellect Config is off" do
      before do
        allow(Panoptes).to receive(:cellect_on).and_return(false)
      end

      it "should never use cellect" do
        expect(subject.strategy(:cellect)).to eq(nil)
      end

      context "when the workflow config has a selection strategy" do
        it "should not ask the workflow" do
          expect(subject).not_to receive(:workflow_strategy)
          expect(subject.strategy(nil)).to eq(nil)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should not query workflow about cellect" do
          expect_any_instance_of(Workflow).not_to receive(:using_cellect?)
          expect(subject.strategy(nil)).to eq(nil)
        end
      end
    end
  end
end
