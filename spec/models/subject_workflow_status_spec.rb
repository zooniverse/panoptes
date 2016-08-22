require 'spec_helper'

RSpec.describe SubjectWorkflowStatus, type: :model do
  let(:count) { create(:subject_workflow_status) }
  it 'should have a valid factory' do
    expect(build(:subject_workflow_status)).to be_valid
  end

  it 'should not be valid without a subject' do
    swc = build(:subject_workflow_status, subject: nil, link_subject_sets: false)
    expect(swc).to_not be_valid
  end

  it 'should not be valid without a workflow' do
    swc = build(:subject_workflow_status, workflow: nil, link_subject_sets: false)
    expect(swc).to_not be_valid
  end

  context "when there is a duplicate subject_id workflow_id entry" do
    let(:duplicate) { count.dup }

    it 'should not allow duplicates' do
      expect(duplicate).to_not be_valid
    end

    it "should raise a uniq index db error" do
      expect{duplicate.save(validate: false)}.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#by_set' do
    it 'retrieves by subject association' do
      sms = create(:set_member_subject)
      swc = create(:subject_workflow_status, subject_id: sms.subject_id)
      expect(SubjectWorkflowStatus.by_set(sms.subject_set_id)).to eq([swc])
    end
  end

  describe '#by_subject_workflow' do
    it 'retrieves by subject association' do
      sms = create(:set_member_subject)
      swc = create(:subject_workflow_status, subject_id: sms.subject_id)
      expect(SubjectWorkflowStatus.by_subject_workflow(sms.subject_id, swc.workflow_id)).to eq(swc)
    end
  end

  describe "#retire!" do
    it 'marks the record as retired' do
      count.retire!
      count.reload
      expect(count.retired?).to be_truthy
    end

    it 'does nothing when the record is already retired' do
      count.retired_at = 5.days.ago
      expect { count.retire! }.not_to change { count.retired_at }
    end

    it 'records the retirement reason' do
      count.retire!("blank")
      expect(count.retirement_reason).to match("blank")
    end
  end

  describe "#retire?" do
    it 'should test against the workflow retirement scheme' do
      d = double
      allow(count.workflow).to receive(:retirement_scheme).and_return(d)
      expect(d).to receive(:retire?).with(count)
      count.retire?
    end
  end
end
