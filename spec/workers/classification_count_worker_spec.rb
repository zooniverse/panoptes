require 'spec_helper'

RSpec.describe ClassificationCountWorker do
  let(:worker) { described_class.new }
  let(:sms) { create(:set_member_subject) }
  let(:workflow_id) { sms.subject_set.workflows.first.id }

  describe "#perform" do
    context "when the count model exists" do
      let!(:count) { create(:subject_workflow_count, set_member_subject: sms, workflow_id: workflow_id)}

      it 'should increment the classifications_count' do
        expect{ worker.perform(sms.subject_id, workflow_id); count.reload }.to change{count.classifications_count}.from(1).to(2)
      end
    end

    context "when the count does not exist" do
      subject do
        SubjectWorkflowCount.where(set_member_subject: sms,
                                         workflow_id: workflow_id).first
      end

      before(:each) do
        worker.perform(sms.subject_id, workflow_id)
      end

      it 'should create a new count' do
        expect(subject).to_not be_nil
      end

      it 'should have a count of 1' do
        expect(subject.classifications_count).to eq(1)
      end
    end

    it 'should queue the retirement worker' do
      expect(RetirementWorker).to receive(:perform_async)
      worker.perform(sms.subject_id, workflow_id)
    end
  end
end
