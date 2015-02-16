require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:sms) { create(:set_member_subject) }
  let(:workflow_id) { sms.subject_set.workflow_id }

  before(:each) do
    stub_cellect_connection
  end
  
  describe "#perform" do
    context "sms is retireable" do
      it 'should retire the sms' do
        allow_any_instance_of(SetMemberSubject).to receive(:retire?).and_return(true)
        worker.perform(sms.id, workflow_id)
        sms.reload
        expect(sms).to be_retired
      end

      it 'should call cellect remote subject' do
        allow_any_instance_of(SetMemberSubject).to receive(:retire?).and_return(true)
        expect(stubbed_cellect_connection).to receive(:remove_subject)
                                               .with(sms.subject_id,
                                                     workflow_id: workflow_id,
                                                     group_id: sms.subject_set_id)
        worker.perform(sms.id, workflow_id)
      end
    end

    context "sms is not retireable" do
      it 'should not retire the sms' do
        allow_any_instance_of(SetMemberSubject).to receive(:retire?).and_return(false)
        worker.perform(sms.id, workflow_id)
        sms.reload
        expect(sms).to_not be_retired
      end
    end
  end
end
