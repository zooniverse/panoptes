require 'spec_helper'

RSpec.describe RetireSubjectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject) { workflow.subjects.first }
  let(:sms) { subject.set_member_subjects.first }
  let(:set) { sms.subject_set }
  let(:sms2) { create(:set_member_subject, subject_set: set) }
  let!(:count) { create(:subject_workflow_status, subject: subject, workflow: workflow) }
  let(:subject_ids) { [sms.subject_id, sms2.subject_id] }

  describe "#perform" do
    it 'should retire the subject for the workflow' do
      expect(count.reload.retired_at).to be_nil
      worker.perform(workflow.id, subject_ids)
      expect(count.reload.retired_at).not_to be_nil
    end

    it 'should retire the subject for the workflow with a reason' do
      reason = "nothing_here"
      worker.perform(workflow.id, subject_ids, reason)
      expect(count.reload.retirement_reason).to eq(reason)
    end

    it 'should ignore unknown workflows' do
      expect(count.reload.retired_at).to be_nil
      worker.perform(-1, subject_ids)
      expect(count.reload.retired_at).to be_nil
    end

    it 'should ignore unknown subjects' do
      expect(count.reload.retired_at).to be_nil
      worker.perform(workflow.id, [-1, sms.subject_id])
      expect(count.reload.retired_at).not_to be_nil
    end

    it 'queues a workflow retired counter' do
      expect(RefreshWorkflowStatusWorker).to receive(:perform_async).with(workflow.id)
      worker.perform(workflow.id, [sms.subject_id])
    end

    it 'queues a cellect retirement if the workflow uses cellect' do
      expect(NotifySubjectSelectorOfRetirementWorker).to receive(:perform_async).with(sms.subject_id, workflow.id)
      worker.perform(workflow.id, [sms.subject_id])
    end

    it 'does not queue workers if something went wrong' do
      allow(Workflow).to receive(:find).and_return(workflow)
      allow(workflow).to receive(:retire_subject).with(sms.subject_id, nil) { raise "some error" }
      expect(RefreshWorkflowStatusWorker).not_to receive(:perform_async)
      expect(NotifySubjectSelectorOfRetirementWorker).not_to receive(:perform_async)
      expect {
        worker.perform(workflow.id, [sms.subject_id])
      }.to raise_error(RuntimeError, 'some error')
    end
  end
end
