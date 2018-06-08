require 'spec_helper'

RSpec.describe SubjectWorkflowStatus, type: :model do
  let(:sws) { create(:subject_workflow_status) }
  it 'should have a valid factory' do
    expect(build(:subject_workflow_status)).to be_valid
  end

  it 'should not be valid without a subject'  do
    built_sws = build(:subject_workflow_status, subject: nil, link_subject_sets: false)
    expect(built_sws).to_not be_valid
  end

  it 'should not be valid without a workflow' do
    built_sws = build(:subject_workflow_status, workflow: nil, link_subject_sets: false)
    expect(built_sws).to_not be_valid
  end

  it 'should be valid with a subject not linked to the workflow' do
    built_sws = build(:subject_workflow_status)
    subject = create(:subject, :with_subject_sets, num_sets: 1)
    built_sws.subject = subject
    expect(built_sws).to be_valid
  end

  context "when re-saving the sws after subject has been unlinked for the workflow" do
    it 'should be valid' do
      subject = create(:subject)
      sws.subject = subject
      expect(sws).to be_valid
    end
  end

  context "when there is a duplicate subject_id workflow_id entry" do
    let(:duplicate) { sws.dup }

    it 'should not allow duplicates' do
      expect(duplicate).to_not be_valid
    end

    it "should raise a uniq index db error" do
      expect{duplicate.save(validate: false)}.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#by_subject_workflow' do
    it 'retrieves by subject association' do
      sms = create(:set_member_subject)
      sws = create(:subject_workflow_status, subject_id: sms.subject_id)
      expect(SubjectWorkflowStatus.by_subject_workflow(sms.subject_id, sws.workflow_id)).to eq(sws)
    end
  end

  describe "#retire!" do
    it 'marks the record as retired' do
      sws.retire!
      sws.reload
      expect(sws.retired?).to be_truthy
    end

    it 'does nothing when the record is already retired' do
      sws.retired_at = 5.days.ago
      expect { sws.retire! }.not_to change { sws.retired_at }
    end

    it 'records the retirement reason' do
      sws.retire!("nothing_here")
      expect(sws.retirement_reason).to match("nothing_here")
    end
  end

  describe "#retire?" do
    it 'should return false if it is already retired' do
      allow(sws).to receive(:retired?).and_return(true)
      expect(sws.workflow).not_to receive(:retirement_scheme)
      expect(sws.retire?).to be_falsey
    end

    it 'should be false on the workflow retirement scheme' do
      expect(sws.retire?).to eq(false)
    end

    it 'should be true with a workflow retirement scheme' do
      custom_scheme = {
        'criteria' => 'classification_count',
        'options' => {'count' => 1}
      }
      sws.workflow.update_column(:retirement, custom_scheme)
      expect(sws.retire?).to eq(true)
    end
  end
end
