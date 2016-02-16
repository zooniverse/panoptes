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

  describe "#classifications_count" do
    let(:relation_instance) { user_group }

    it_behaves_like "it has a cached counter for classifications"
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
