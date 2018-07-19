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

  describe "#display_name" do
    it 'should validate presence' do
      expect(build(:user_group, display_name: "")).to_not be_valid
    end
  end

  describe '#name' do
    it 'should not have whitespace' do
      expect(build(:user_group, name: " asdf asdf")).to_not be_valid
    end

    it 'should not have weird characters' do
      expect(build(:user_group, name: "$asdfasdf")).to_not be_valid
    end

    it 'should not enfore a minimum length' do
      expect(build(:user, login: "1")).to be_valid
    end

    it 'should have non-blank error' do
      ug = build(:user_group, name: "")
      ug.valid?
      expect(ug.errors[:name]).to include("can't be blank")
    end

    it 'should validate uniqueness' do
      name = "FancyUserGroup"
      aggregate_failures "different cases" do
        expect{ create(:user_group, name: name) }.not_to raise_error
        expect{ create(:user_group, name: name.upcase) }.to raise_error(ActiveRecord::RecordInvalid)
        expect{ create(:user_group, name: name.downcase) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'should constrain database uniqueness' do
      user_group = create :user_group
      dup_group = create :user_group

      expect {
        dup_group.update_attribute 'name', user_group.name.upcase
      }.to raise_error ActiveRecord::RecordNotUnique
    end

    it "should have the correct case-insensitive uniqueness error" do
      user_group = create(:user_group)
      dup_user_group = build(:user_group, name: user_group.name.upcase)
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

  describe "#memberships" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many memberships" do
      expect(user_group.memberships).to all( be_a(Membership) )
    end
  end

  describe "#active_memberships" do
    let(:user_group) { create(:user_group_with_users) }

    it "should have many active memberships" do
      memberships = user_group.active_memberships
      expect(memberships).to all( be_a(Membership) )
      expect(memberships.map(&:identity)).to all( be(false) )
    end
  end

  describe "#identity_membership" do
    let(:user_group) { create(:identity_user_group) }

    it "should have one identity membership" do
      membership = user_group.identity_membership
      expect(membership).to be_a(Membership)
      expect(membership.identity).to be(true)
    end
  end

  describe "#owned_resources" do
    let(:user_group) { create(:user_group_with_projects) }
    let(:owned_projects) { user_group.owned_resources.map(&:resource) }
    let(:projects) do
      acls = AccessControlList.where(user_group_id: user_group.id, resource_type: "Project")
      acls.map(&:resource)
    end

    it "should link to the owned_resources" do
      expect(owned_projects).to eq(projects)
    end

    context "when the owned resource has other roles" do

      it "should still link to the owned_resources" do
        acl = user_group.owned_resources.first
        acl.update_column(:roles, ["owner", "tester"])
        expect(owned_projects).to eq(projects)
      end
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

  describe '#verify_join_token' do
    it 'returns true if the join token matches' do
      result = user_group.verify_join_token(user_group.join_token)
      expect(result).to be_truthy
    end

    it 'returns false if the join token does not match' do
      result = user_group.verify_join_token('wrong')
      expect(result).to be_falsey
    end

    it 'returns false if the group does not have a join token' do
      user_group.join_token = nil
      result = user_group.verify_join_token(user_group.join_token)
      expect(result).to be_falsey
    end
  end

  describe '#identity?' do
    let(:user) { create :user }

    it 'returns true if there is any membership marked as identity' do
      user_group = create(:identity_user_group)
      expect(user_group.identity?).to be_truthy
    end

    it 'returns false if there are only normal memberships' do
      create(:membership, user: user, user_group: user_group, roles: ['group_admin'])
      expect(user_group.identity?).to be_falsey
    end

    it 'returns false if there are no members' do
      expect(user_group.identity?).to be_falsey
    end
  end

  describe '#has_admin?' do
    let(:user) { create :user }

    it 'returns true if the user is a group_admin' do
      create(:membership, user: user, user_group: user_group, roles: ['group_admin'])
      expect(user_group.has_admin?(user)).to be_truthy
    end

    it 'returns false if the user is a normal group member' do
      create(:membership, user: user, user_group: user_group, roles: ['group_member'])
      expect(user_group.has_admin?(user)).to be_falsey
    end

    it 'returns false if the user is not in the group' do
      expect(user_group.has_admin?(user)).to be_falsey
    end
  end
end
