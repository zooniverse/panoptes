require "spec_helper"
require 'subjects/cellect_session'

RSpec.describe EnqueueSubjectQueueWorker do
  subject { described_class.new }
  let(:workflow) { create(:workflow_with_subject_set) }
  let(:subject_set) { workflow.subject_sets.first }
  let(:user) { workflow.project.owner }
  let(:queue) do
    create(:subject_queue,
      workflow: workflow,
      user: user,
      subject_set_id: subject_set.id
    )
  end

  describe "#perform" do
    it "should not raise an error if there is no queue" do
      expect { subject.perform(-1, nil) }.not_to raise_error
    end

    it "should not attempt to queue an empty selection set" do
      expect_any_instance_of(SubjectQueue).not_to receive(:enqueue_update)
      subject.perform(queue.id, [])
    end

    it "should enqueue new data" do
      ids = [1,3,2]
      subject.perform(queue.id, ids)
      expect(queue.reload.set_member_subject_ids).to match_array(ids)
    end
  end
end
