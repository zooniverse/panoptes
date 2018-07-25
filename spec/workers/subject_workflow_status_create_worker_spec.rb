require 'spec_helper'

RSpec.describe SubjectWorkflowStatusCreateWorker do
  let(:worker) { described_class.new }
  let(:sms) do
    create(:set_member_subject)
  end
  let(:workflow) { sms.workflows.first }
  let(:workflow_id) { workflow.id }
  let(:subject_id) { sms.subject_id }
  let(:worker) do
    SubjectWorkflowStatusCreateWorker.new
  end

  describe "#perform" do
    it "should not raise if the subject can't be found" do
      expect {
        worker.perform(-1, workflow_id)
      }.not_to raise_error
    end

    it "should not raise if the workflow can't be found" do
      expect {
        worker.perform(subject_id, -1)
      }.not_to raise_error
    end

    it "should create a SubjectWorkflowStatus record" do
      expect {
        worker.perform(subject_id, workflow_id)
      }.to change {
        SubjectWorkflowStatus.count
      }.by(1)
    end

    it "should create the correctly linked SubjectWorkflowStatus record" do
      expect(
        SubjectWorkflowStatus.where(
          subject_id: subject_id,
          workflow_id: workflow_id
        ).exists?
      ).to be_falsey
      worker.perform(subject_id, workflow_id)
      expect(
        SubjectWorkflowStatus.where(
          subject_id: subject_id,
          workflow_id: workflow_id
        ).exists?
      ).to be_truthy
    end

    it "should ignore already created SubjectWorkflowStatus record" do
      create(:subject_workflow_status, subject: sms.subject, workflow: workflow)
      expect {
        worker.perform(subject_id, workflow_id)
      }.not_to change {
        SubjectWorkflowStatus.count
      }
    end

    it "should ignore subjects that aren't linked to the workflow" do
      unlinked_workflow = create(:workflow)
      expect {
        worker.perform(subject_id, unlinked_workflow.id)
      }.not_to change {
        SubjectWorkflowStatus.count
      }
    end
  end
end
