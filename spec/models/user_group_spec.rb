require 'spec_helper'

describe UserGroup, :type => :model do
  let(:user_group) { create(:user_group) }
  let(:named) { user_group }
  let(:unnamed) { build(:user_group, uri_name: nil) }
  let(:activatable) { user_group }
  let(:owner) { user_group }
  let(:owned) { build(:project, owner: owner) }

  it_behaves_like "is uri nameable"
  it_behaves_like "activatable"
  it_behaves_like "is an owner"

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

  describe "#subjects" do
    let(:relation_instance) { user_group }

    it_behaves_like "it has a subjects association"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { user_group }

    it_behaves_like "it has a cached counter for classifications"
  end

  describe "#uri_name" do

    it "should destroy the uri_name on user destruction" do
      user_group
      expect{ user_group.destroy }.to change{ UriName.count }.from(1).to(0)
    end

    context "when the uri_name association is blank" do

      before(:each) do
        user_group.uri_name = nil
      end

      it "should be invalid without a uri_name" do
        expect(user_group.valid?).to be false
      end

      it "should have the correct error message" do
        user_group.valid?
        expect(user_group.errors[:uri_name]).to include("can't be blank")
      end
    end
  end
end
