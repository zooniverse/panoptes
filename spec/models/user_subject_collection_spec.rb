require 'spec_helper'

describe UserSubjectCollection, :type => :model do
  it "should have a valid factory" do
    expect(build(:user_subject_collection)).to be_valid
  end

  it "must have an owner" do
    expect(build(:user_subject_collection, owner: nil)).to_not be_valid
  end
end
