require 'spec_helper'

describe UserGroup, :type => :model do
  let(:user_group) { create(:user_group) }

  it "should have a valid factory" do
    expect(build(:user_group)).to be_valid
  end

  describe "#users" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many users" do
      expect(user_group.users).to all( be_a(User) )
    end

    it "should have on user for each membership" do
      ug = user_group
      expect(ug.users.length).to eq(ug.user_group_memberships.length)
    end
  end

  describe "#user_group_memberships" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many user group memberships" do
      expect(user_group.user_group_memberships).to all( be_a(UserGroupMembership) ) 
    end
  end


end
