require 'spec_helper'

describe UserGroup, :type => :model do
  let(:user_group) { create(:user_group) }
  let(:named) { user_group }
  let(:unnamed) { build(:user_group, uri_name: nil) }

  it_behaves_like "is uri nameable"

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
      expect(ug.users.length).to eq(ug.memberships.length)
    end
  end

  describe "#user_group_memberships" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many user group memberships" do
      expect(user_group.memberships).to all( be_a(Membership) )
    end
  end

  describe "#classifcations_count" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have a zero classifcations count" do
      expect(user_group.classifications_count).to eq(0)
    end

    context "when a user in the group submits a classfication" do

      it "should have incremented the count" do
        user = user_group.users.sample
        create(:classification, user: user)
        user.reload
        expect(user_group.classifications_count).to eq(1)
      end
    end
  end
end
