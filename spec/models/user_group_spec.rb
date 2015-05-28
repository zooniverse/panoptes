require 'spec_helper'

describe UserGroup, :type => :model do
  let(:user_group) { create(:user_group) }
  let(:named) { user_group }
  let(:activatable) { user_group }
  let(:owner) { user_group }
  let(:owned) { build(:project, owner: owner) }
  let(:locked_factory) { :user_group }
  let(:locked_update) { {display_name: "A-different_name"} }

  it_behaves_like "optimistically locked"

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
        expect(UserGroup.scope_for(:show, ApiUser.new(member))).to include(user_group)
      end

      it "should return groups that are public" do
        expect(UserGroup.scope_for(:show, ApiUser.new(member))).to include(public_group)
      end

      it "should not return private groups a user is not a member of" do
        expect(UserGroup.scope_for(:show, ApiUser.new(member))).not_to include(private_group)
      end
    end
  end

  describe "#display_name" do
    it 'should validate presence' do
      expect(build(:user_group, display_name: "")).to_not be_valid
    end

    it 'should not have whitespace' do
      expect(build(:user_group, display_name: " asdf asdf")).to_not be_valid
    end

    it 'should not have a dollar sign' do
      expect(build(:user_group, display_name: "$asdfasdf")).to_not be_valid
    end

    it 'should not ahve an at sign' do
      expect(build(:user_group, display_name: "@asdfasdf")).to_not be_valid
    end

    it 'should have non-blank error' do
      ug = build(:user_group, display_name: "")
      ug.valid?
      expect(ug.errors[:display_name]).to include("can't be blank")
    end

    context "when an identity group" do
      let!(:stub_identity?) do
        allow_any_instance_of(UserGroup).to receive(:identity?).and_return(true)
      end

      it 'should allow a whitespace' do
        expect(build(:user_group, display_name: " asdf asdf")).to be_valid
      end

      it 'should allow a dollar sign' do
        expect(build(:user_group, display_name: "$asdfasdf")).to be_valid
      end

      it 'should allow an at sign' do
        expect(build(:user_group, display_name: "@asdfasdf")).to be_valid
      end

      it 'should have non-blank error' do
        ug = build(:user_group, display_name: "")
        ug.valid?
        expect(ug.errors[:display_name]).to include("can't be blank")
      end
    end

    it 'should validate uniqueness' do
      name = "FancyUserGroup"
      expect{ create(:user_group, display_name: name) }.to_not raise_error
      expect{ create(:user_group, display_name: name.upcase) }.to raise_error
      expect{ create(:user_group, display_name: name.downcase) }.to raise_error
    end

    it "should have the correct case-insensitive uniqueness error" do
      user_group = create(:user_group)
      dup_user_group = build(:user_group, display_name: user_group.display_name.upcase)
      dup_user_group.valid?
      expect(dup_user_group.errors[:name]).to include("has already been taken")
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

  describe "#projects" do
    let(:user_group) { create(:user_group_with_projects) }

    it 'should have many projects' do
      expect(user_group.projects).to all( be_a(Project) )
    end
  end

  describe "#collections" do
    let(:user_group) { create(:user_group_with_collections) }

    it 'should have many collections' do
      expect(user_group.collections).to all( be_a(Collection) )
    end
  end

  describe "#classifcations_count" do
    let(:relation_instance) { user_group }

    it_behaves_like "it has a cached counter for classifications"
  end

  describe "#create_url_slug" do
    let(:group) { create(:user_group) }
    context "when the display_name has not changed" do
      it 'should not change the url slug' do
        old_slug = group.slug
        group.create_url_slug
        expect(group.slug).to eq(old_slug)
      end
    end

    context "when to_url is empty" do
      it 'should set the to slug to user-id' do
        group.display_name = "(-_-)"
        group.create_url_slug
        expect(group.slug).to eq("user-#{group.id}")
      end
    end

    context "when otherwise" do
      it 'should set the slug to the to_url version of the group\'s name' do
        group.display_name = "hey there!"
        group.create_url_slug
        expect(group.slug).to eq("hey-there")
      end
    end
  end
end
