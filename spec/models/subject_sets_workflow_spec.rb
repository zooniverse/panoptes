require 'spec_helper'

RSpec.describe SubjectSetsWorkflow do
  it "should have a valid factory" do
    expect(build(:subject_sets_workflow)).to be_valid
  end

  it "should validate the uniqueness of the workflow scoped to set id", :aggregate_failures do
    ssw = create(:subject_sets_workflow)
    dup = ssw.dup
    expect(dup.valid?).to be_falsey
    expect(dup.errors[:workflow_id]).to include("has already been taken")
  end
end
