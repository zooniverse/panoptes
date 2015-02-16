require 'spec_helper'

RSpec.describe ClassificationCountWorker do
  let(:worker) { described_class.new }
  let(:sms) { create(:set_member_subject) }
  let(:workflow_id) { sms.subject_set.workflow_id }
  
  describe "#perform" do
    it 'should increment the classification_count' do
      expect{ worker.perform(sms.subject_id, workflow_id); sms.reload }.to change{sms.classification_count}.from(0).to(1)
    end

    it 'should queue the retirement worker' do
      expect(RetirementWorker).to receive(:perform_async).with(sms.id, workflow_id)
      worker.perform(sms.subject_id, workflow_id)
    end
  end
end
