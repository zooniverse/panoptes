require 'spec_helper'

RSpec.describe SubjectWorkflowCount, type: :model do
  let(:count) { create(:subject_workflow_count) }
  it 'should have a balid factory' do
    expect(build(:subject_workflow_count)).to be_valid
  end

  it 'should not be valid without a set_member_subject' do
    expect(build(:subject_workflow_count, set_member_subject: nil)).to_not be_valid
  end

  it 'should not be valid without a workflow' do
    expect(build(:subject_workflow_count, workflow: nil)).to_not be_valid
  end

  describe "#retire!" do
    it 'should retire the subject for the workflow' do
      expect_any_instance_of(SubjectLifecycle).to receive(:retire_for).with(count.workflow)
      count.retire!
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
