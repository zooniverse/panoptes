require 'spec_helper'

describe UserGroupMembership, :type => :model do
  let(:user_group_membership) { create(:user_group_membership) }
  it "should have a valid factory" do
    expect(build(:user_group_membership)).to be_valid
  end

  describe "#user_group" do
    it "must have a user group" do
      expect(build(:user_group_membership, user_group: nil)).to_not be_valid
    end

    it "should belong to a user group" do
      expect(user_group_membership.user_group).to be_a(UserGroup)
    end
  end

  describe "#user" do
    it "must have a user" do
      expect(build(:user_group_membership, user: nil)).to_not be_valid
    end

    it "should belong to a user" do
      expect(user_group_membership.user).to be_a(User)
    end
  end
  
  describe "#state" do
    it "must have a state" do
      expect(build(:user_group_membership, state: nil)).to_not be_valid
    end
  end
end
