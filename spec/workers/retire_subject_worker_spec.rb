require 'spec_helper'

RSpec.describe RetireSubjectWorker do
  let(:worker) { described_class.new }
  let(:workflow) { create(:workflow_with_subjects, num_sets: 1) }
  let(:subject) { workflow.subjects.first }
  let(:sms) { subject.set_member_subjects.first }
  let(:set) { sms.subject_set }
  let(:sms2) { create(:set_member_subject, subject_set: set) }
  let(:count) { create(:subject_workflow_status, subject: subject, workflow: workflow) }
  let(:count2) { create(:subject_workflow_status, subject: sms2.subject, workflow: workflow) }
  let(:subject_ids) { [sms.subject_id, sms2.subject_id] }

  describe "#perform" do
    it 'should handle an unknow workflow' do
      expect { worker.perform(-1, subject.id) }.not_to raise_error
    end

    it 'should call the retirement worker with the subject workflow status resource' do
      expect(RetirementWorker).to receive(:perform_async).with(count.id, nil).ordered
      expect(RetirementWorker).to receive(:perform_async).with(count2.id, nil).ordered
      worker.perform(workflow.id, subject_ids)
    end

    it 'should pass the reason to the retirement worker' do
      reason = "nothing_here"
      expect(RetirementWorker).to receive(:perform_async).with(count.id, reason)
      worker.perform(workflow.id, subject.id, reason)
    end

    it 'should not do any work if the workflow is not found' do
      expect(worker).not_to receive(:subject_workflow_status)
      expect(RetirementWorker).not_to receive(:perform_async)
      worker.perform(-1, subject.id)
    end

    describe "creating the sws resource" do
      it 'should raise if there is a problem with the workflow' do
        allow(worker).to receive(:workflow_exists?).and_return(true)
        expect {
          worker.perform(-1, subject.id)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should raise if there is a problem with the subject' do
        allow(worker).to receive(:workflow_exists?).and_return(true)
        expect {
          worker.perform(workflow.id, -1)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
