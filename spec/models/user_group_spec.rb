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

  describe "#display_name" do

    it 'should validate presence' do
      ug = build(:user_group, display_name: "")
      expect(ug.valid?).to be false
    end

    it 'should have non-blank error' do
      ug = build(:user_group, display_name: "")
      ug.valid?
      expect(ug.errors[:display_name]).to include("can't be blank")
    end

    it 'should validate uniqueness' do
      name = "FancyUserGroup"
      expect{ UserGroup.create!(name: name, display_name: name) }.to_not raise_error
      expect{ UserGroup.create!(name: name.upcase, display_name: name.upcase) }.to raise_error
      expect{ UserGroup.create!(name: name.downcase, display_name: name.downcase) }.to raise_error
    end

    it "should have the correct case-insensitive uniqueness error" do
      user_group = create(:user_group)
      dup_user_group = build(:user_group, display_name: user_group.display_name.upcase)
      dup_user_group.valid?
      expect(dup_user_group.errors[:display_name]).to include("has already been taken")
    end

    context "when a user with the same login exists" do
      let!(:user_group) { build(:user_group) }
      let!(:user) { create(:user, login: user_group.display_name) }

      it "should not be valid" do
        expect(user_group).to_not be_valid
      end

      it "should have the correct error message on the uri_name association" do
        user_group.valid?
        expect(user_group.errors[:"uri_name.name"]).to include("has already been taken")
      end
    end
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
end
