require 'spec_helper'

describe UserGroup, :type => :model do
  let(:user_group) { create(:user_group) }
  let(:named) { user_group }
  let(:unnamed) do
    unnamed = build(:user_group)
    unnamed.owner_name = nil
    unnamed
  end
  let(:activatable) { user_group }
  let(:owner) { user_group }
  let(:owned) { build(:project, owner: owner) }

  it_behaves_like "is owner nameable"
  it_behaves_like "activatable"
  it_behaves_like "is an owner"

  it "should have a valid factory" do
    expect(build(:user_group)).to be_valid
  end

  describe "::scope_for" do
    context "action is show" do
      let(:member) do
        membership = create(:membership,
                            state: :active,
                            user_group: user_group,
                            roles: ["group_member"])
        membership.user
      end

      let!(:public_group) do
        create(:user_group, private: false)
      end

      let(:private_group) do
        create(:user_group, private: true)
      end
      
      it "should return groups the user is an active member of" do
        expect(UserGroup.scope_for(:show, member)).to include(user_group)
      end

      it "should return groups that are public" do
        expect(UserGroup.scope_for(:show, member)).to include(public_group)
      end

      it "should not return private groups a user is not a member of" do
        expect(UserGroup.scope_for(:show, member)).not_to include(private_group)
      end
    end
  end

  describe "#name" do

    it 'should validate presence' do
      ug = build(:user_group, name: "")
      expect(ug.valid?).to be false
    end

    it 'should have non-blank error' do
      ug = build(:user_group, name: "")
      ug.valid?
      expect(ug.errors[:name]).to include("can't be blank")
    end

    it 'should validate uniqueness' do
      name = "FancyUserGroup"
      expect{ create(:user_group, name: name) }.to_not raise_error
      expect{ create(:user_group, name: name.upcase) }.to raise_error
      expect{ create(:user_group, name: name.downcase) }.to raise_error
    end

    it "should have the correct case-insensitive uniqueness error" do
      user_group = create(:user_group)
      dup_user_group = build(:user_group, name: user_group.name.upcase)
      dup_user_group.valid?
      expect(dup_user_group.errors[:name]).to include("has already been taken")
    end

    context "when a user with the same login exists" do
      let!(:user_group) { build(:user_group) }
      let!(:user) { create(:user, login: user_group.name) }

      it "should not be valid" do
        expect(user_group).to_not be_valid
      end

      it "should have the correct error message on the owner_name association" do
        user_group.valid?
        expect(user_group.errors[:"owner_name.name"]).to include("has already been taken")
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
