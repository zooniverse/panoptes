require 'spec_helper'

RSpec.describe ReloadNonLoggedInQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:ids) { (1..100).to_a }
  let(:capped_ids) { ids.slice(0, 20) }

  before(:each) do
    allow_any_instance_of(Subjects::PostgresqlSelection)
      .to receive(:select).and_return(ids)
  end

  describe "#perform" do

    it 'should not try to update an non-existant queue', :aggregate_failures do
      expect(subject).not_to receive(:selected_subject_ids)
      expect_any_instance_of(SubjectQueue).not_to receive(:update_queue_ids)
      subject.perform(workflow.id)
    end

    it 'should not raise an error with a non-existant workflow' do
      expect do
        subject.perform(-1)
      end.to_not raise_error
    end

    context "with an existing queue" do
      let(:os) { ids.last + 1 }
      let!(:queue) do
        create(:subject_queue,
               workflow: workflow,
               user: nil,
               set_member_subject_ids: [os])
      end

      it "should not attempt to enqueue an empty set" do
        allow(subject).to receive(:selected_subject_ids).and_return([])
        expect_any_instance_of(SubjectQueue).not_to receive(:update_ids)
        subject.perform(workflow.id)
      end

      it 'should update the queue ids' do
        subject.perform(workflow.id)
        queue.reload
        expect(queue.set_member_subject_ids)
          .to match_array(capped_ids)
      end

      context "grouped / non-grouped workflows and queues" do
        let(:queue_subject_set) { nil }
        let(:grouped) { false }
        let!(:queue) do
          create(:subject_queue,
                 workflow: workflow,
                 user: nil,
                 subject_set: queue_subject_set,
                 set_member_subject_ids: [os])
        end

        before(:each) do
          allow_any_instance_of(Workflow)
            .to receive(:grouped)
            .and_return(grouped)
        end

        it "should reload the queue even passing a non-grouped subject set" do
          aggregate_failures("by set lookup") do
            expect(SubjectQueue).to receive(:by_set)
              .with(nil)
              .and_call_original
            subject.perform(workflow.id, subject_set.id)
            expect(queue.reload.set_member_subject_ids)
              .to match_array(capped_ids)
          end
        end

        context "when the workflow is grouped" do
          let(:queue_subject_set) { subject_set }
          let(:grouped) { true }

          it "should reload the queue with a subject set" do
            aggregate_failures("by set lookup") do
              expect(SubjectQueue).to receive(:by_set).with(subject_set.id)
                .and_call_original
              subject.perform(workflow.id, subject_set.id)
              expect(queue.reload.set_member_subject_ids)
                .to match_array(capped_ids)
            end
          end
        end
      end
    end
  end
end
