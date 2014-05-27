require 'spec_helper'

describe UserGroupMembership, :type => :model do
  it "should have a valid factory" do
    expect(build(:user_group_membership)).to be_valid
  end

  it "must have a user group" do
    expect(build(:user_group_membership, user_group: nil)).to_not be_valid
  end

  it "must have a user" do
    expect(build(:user_group_membership, user: nil)).to_not be_valid
  end

  it "must have a state" do
    expect(build(:user_group_membership, state: nil)).to_not be_valid
  end
end
