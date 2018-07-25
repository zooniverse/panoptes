require 'spec_helper'

RSpec.describe SubjectSetStatusesCreateWorker do
  let(:worker) { described_class.new }
  let(:subject_set) { create(:subject_set_with_subjects) }
  let(:workflow) { subject_set.workflows.first }
  let(:workflow_id) { workflow.id }
  let(:subject_ids) { subject_set.set_member_subjects.pluck(:subject_id) }
  let(:worker) do
    SubjectSetStatusesCreateWorker.new
  end

  describe "#perform" do
    it "should not raise if the subject set can't be found" do
      expect {
        worker.perform(-1, workflow_id)
      }.not_to raise_error
    end

    it "should not raise if the workflow can't be found" do
      expect {
        worker.perform(subject_set.id, -1)
      }.not_to raise_error
    end

    it "should call a SubjectWorkflowStatusCreateWorker for each subject" do
      subject_ids.each do |subject_id|
        expect(SubjectWorkflowStatusCreateWorker)
          .to receive(:perform_async)
          .with(subject_id, workflow_id)
      end
      worker.perform(subject_set.id, workflow_id)
    end
  end
end
