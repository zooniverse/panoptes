require 'spec_helper'

RSpec.describe ReloadNonLoggedInQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:subject_ids) { (1..100).to_a}

  before(:each) do
    allow_any_instance_of(Subjects::PostgresqlSelection).to receive(:select).and_return(subject_ids)
  end

  describe "#perform" do
    context "no existing queue" do
      it 'should create a subject queue with the default number of items' do
        subject.perform(workflow.id)
        queue = SubjectQueue.find_by(workflow: workflow)
        expect(queue.set_member_subject_ids.length).to eq(100)
      end
    end

    context "when the workflow does not exist" do
      it 'should not raise an error' do
        expect do
          subject.perform(-1)
        end.to_not raise_error
      end
    end

    context "with an existing queue" do
      let(:os) { subject_ids.last + 1 }
      let!(:queue) do
        create(:subject_queue,
               workflow: workflow,
               user: nil,
               set_member_subject_ids: [os])
      end

      it 'should update the queued subjects' do
        subject.perform(workflow.id)
        queue.reload
        expect(queue.set_member_subject_ids).to match_array(subject_ids)
      end

      context "grouped / non-grouped workflows and queues" do
        let!(:queue) do
          create(:subject_queue,
                 workflow: workflow,
                 user: nil,
                 subject_set: queue_subject_set,
                 set_member_subject_ids: [os])
        end

        before(:each) do
          allow_any_instance_of(Workflow).to receive(:grouped).and_return(grouped)
        end

        context "when the workflow is not grouped" do
          let(:queue_subject_set) { nil }
          let(:grouped) { false }

          it "should reload the queue without a subject set" do
            aggregate_failures("by set lookup") do
              expect(SubjectQueue).to receive(:by_set).with(nil).and_call_original
              subject.perform(workflow.id, subject_set.id)
              expect(queue.reload.set_member_subject_ids).to match_array(subject_ids)
            end
          end
        end

        context "when the workflow is grouped" do
          let(:queue_subject_set) { subject_set }
          let(:grouped) { true }

          it "should reload the queue with a subject set" do
            aggregate_failures("by set lookup") do
              expect(SubjectQueue).to receive(:by_set).with(subject_set.id).and_call_original
              subject.perform(workflow.id, subject_set.id)
              expect(queue.reload.set_member_subject_ids).to match_array(subject_ids)
            end
          end
        end
      end
    end
  end
end
