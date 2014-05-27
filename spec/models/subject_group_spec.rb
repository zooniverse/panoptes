require 'spec_helper'

describe SubjectGroup, :type => :model do
  it "must have a project" do
    expect(build(:subject_group)).to be_valid
    expect(build(:subject_group, project: nil)).to_not be_valid
  end
end
