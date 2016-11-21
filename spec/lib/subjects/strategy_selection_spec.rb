require "spec_helper"
require 'subjects/cellect_session'

RSpec.describe Subjects::StrategySelection do
  let(:strategy) { nil }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:smses) { subject_set.set_member_subjects }
  let(:user) { workflow.project.owner }
  let(:limit) { SubjectQueue::DEFAULT_LENGTH }
  subject do
    described_class.new(workflow, user, subject_set.id, limit, strategy)
  end

  describe "#select" do

    it "should call the complete remover after selection", :aggregate_failures do
      expect(subject).to receive(:strategy_sms_ids).and_return([1,2,3]).ordered
      expect(Subjects::CompleteRemover)
        .to receive(:new)
        .with(user, workflow, an_instance_of(Array))
        .ordered
        .and_return(instance_double(Subjects::CompleteRemover, incomplete_ids: [1]))
      subject.select
    end

    describe "remove completed after selection" do
      let(:retired_workflow) { workflow }
      let(:sms) { smses[0] }
      let(:result) { subject.select }

      before do
        allow(subject).to receive(:select_sms_ids).and_return([:default, smses.map(&:id)])
      end

      context "retired subjects" do
        let!(:sws) do
          create(:subject_workflow_status,
            subject: sms.subject,
            workflow: retired_workflow,
            retired_at: Time.zone.now
          )
        end

        it 'should not return retired subjects' do
          expect(result).not_to include(sms.id)
        end

        context "when the sms is retired for a different workflow" do
          let(:retired_workflow) { create(:workflow_with_subjects, num_sets: 1) }

          it 'should return all the subjects' do
            expect(result).to include(sms.id)
          end
        end
      end

      context "seen subjects" do
        let!(:seens) do
          create(:user_seen_subject, user: user, workflow: workflow, subject_ids: [sms.subject.id])
        end

        it 'should not return seen subjects' do
          expect(result).not_to include(sms.id)
        end

      end
    end

    context "when selecting via strategy param" do
      let(:result_ids) { [1] }

      it "should fallback from the override strategy" do
        expect_any_instance_of(Subjects::PostgresqlSelection)
          .to receive(:select)
          .and_call_original
        subject.select
      end

      context "with cellect" do
        let(:strategy) { :cellect }
        let(:run_selection) { subject.select }
        before do
          allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(true)
        end

        it "should use the cellect client" do
          cellect_params = [ workflow.id, user.id, subject_set.id, limit ]
          expect(Subjects::CellectClient)
            .to receive(:get_subjects)
            .with(*cellect_params)
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

        context "when the cellect client can't reach a server" do
          it "should fall back to postgres strategy" do
            allow(Subjects::CellectClient).to receive(:get_subjects)
              .and_raise(Subjects::CellectClient::ConnectionError)
            expect_any_instance_of(Subjects::PostgresqlSelection)
              .to receive(:select)
              .and_call_original
            run_selection
          end
        end
      end

      context "with cellect_ex" do
        let(:strategy) { :cellect_ex }
        let(:run_selection) { subject.select }

        it "should use the cellect_ex client" do
          params = [ workflow.id, user.id, subject_set.id, limit ]
          expect(Subjects::CellectExSelection)
            .to receive(:get_subjects)
            .with(*params)
            .and_return(result_ids)
          run_selection
        end

        it "should convert the cellect_ex subject_ids to panoptes sms_ids" do
          allow(Subjects::CellectExSelection).to receive(:get_subjects)
            .and_return(result_ids)
          expect(SetMemberSubject).to receive(:by_subject_workflow)
            .with(result_ids, workflow.id).and_call_original
          run_selection
        end
      end
    end
  end

  describe "#strategy" do
    let(:cellect_size) { Panoptes.cellect_min_pool_size }

    before do
      allow(subject).to receive(:workflow).and_return(workflow)
    end

    it "should fall back to postgresql strategy when not set" do
      expect(subject.strategy).to eq(nil)
    end

    context "when Cellect config is on" do
      before do
        allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(true)
        allow(Panoptes.flipper).to receive(:enabled?).with("cellect_ex").and_return(true)
      end

      context "when providing cellect strategy param" do
        let(:strategy) { :cellect }

        it "should use the supplied strategy" do
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "when the workflow is set to use cellect" do
        it "should use the workflow config strategy" do
          allow(workflow).to receive(:subject_selection_strategy).and_return("cellect")
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should use the cellect strategy" do
          allow(workflow).to receive_message_chain("set_member_subjects.count") do
            cellect_size
          end
          expect(subject.strategy).to eq(:cellect)
        end
      end

      context "workflow is set to use cellect cellect and large subject set size" do
        it "should only use the workflow strategy", :aggregate_failures do
          allow(workflow).to receive(:subject_selection_strategy).and_return("cellect")
          allow(workflow)
            .to receive(:cellect_size_subject_space?)
            .and_return(true)
            .and_call_original
          expect(workflow).not_to receive(:set_member_subjects)
          expect(subject.strategy).to eq(:cellect)
        end
      end
    end

    context "when Cellect Config is off" do
      before do
        allow(Panoptes.flipper).to receive(:enabled?).with("cellect").and_return(false)
        allow(Panoptes.flipper).to receive(:enabled?).with("cellect_ex").and_return(false)
      end

      context "when providing cellect strategy param" do
        let(:strategy) { :cellect }

        it "should never use cellect" do
          expect(subject.strategy).to eq(nil)
        end
      end

      context "when the workflow config has a selection strategy" do
        it "should not ask the workflow" do
          expect(subject).not_to receive(:workflow_strategy)
          expect(subject.strategy).to eq(nil)
        end
      end

      context "when the number of set_member_subjects is large" do
        it "should not query workflow about cellect" do
          expect_any_instance_of(Workflow).not_to receive(:using_subject_selection_strategy)
          expect(subject.strategy).to eq(nil)
        end
      end
    end

    describe 'cellect_ex' do
      context "when providing cellect_ex strategy param" do
        let(:strategy) { :cellect_ex }

        it "should use the supplied strategy" do
          expect(subject.strategy).to eq(:cellect_ex)
        end
      end

      context "when the workflow is set to use cellect_ex" do
        it "should use the workflow config strategy" do
          allow(workflow).to receive(:subject_selection_strategy).and_return("cellect_ex")
          expect(subject.strategy).to eq(:cellect_ex)
        end
      end

      context 'when the workflow has a lot of subjects' do
        it 'should still use cellect_ex' do
          allow(workflow).to receive(:subject_selection_strategy).and_return("cellect_ex")
          allow(workflow).to receive_message_chain("set_member_subjects.count") do
            cellect_size
          end
          expect(subject.strategy).to eq(:cellect_ex)
        end
      end
    end
  end
end
