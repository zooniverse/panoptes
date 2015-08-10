require 'spec_helper'

RSpec.describe ReloadNonLoggedInQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let!(:subjects) do
    create_list(:set_member_subject, 100, subject_set: workflow.subject_sets.first)
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
      let(:os) { create(:subject).id }
      let!(:queue) do
        create(:subject_queue,
               workflow: workflow,
               user: nil,
               set_member_subject_ids: [os])
      end

      before(:each) do
        subject.perform(workflow.id)
        queue.reload
      end

      it 'should update the queued subjects' do
        expect(queue.set_member_subject_ids).to match_array(subjects.map(&:id))
      end
    end
  end
end
