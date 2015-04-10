require 'spec_helper'

RSpec.describe RetirementWorker do
  let(:worker) { described_class.new }
  let(:sms) { create(:set_member_subject) }
  let(:workflow_id) { sms.subject_set.workflow_id }

  describe "#perform" do
    context "sms is retireable" do
      before(:each) do
        allow_any_instance_of(SetMemberSubject).to receive(:retire?).and_return(true)
      end
      
      it 'should retire the sms' do
        worker.perform(sms.id, workflow_id)
        sms.reload
        expect(sms).to be_retired
      end

      it "should increment the subject set's retirement count" do
        expect{ worker.perform(sms.id, workflow_id) }.to change{
          SubjectSet.find(sms.subject_set_id).retired_set_member_subjects_count
        }.from(0).to(1)
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
