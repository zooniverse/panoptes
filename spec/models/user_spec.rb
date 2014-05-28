require 'spec_helper'

describe User, :type => :model do
  let(:user) { create(:user) }

  describe "#password_required?" do
    it 'should require a password when creating with a new user' do
      expect{ User.create!(login: "t", password: "password1", email: "test@example.com") }
        .to_not raise_error

      expect{ User.create!(login: "t", email: "test@example.com") }
        .to raise_error
    end

    it 'should not require a password when creating a user from an import' do
      expect{ User.create!(login: "t", hash_func: 'sha1', email: "test@example.com") }
        .to_not raise_error
    end
  end

  describe "#valid_password?" do
    it 'should validate user with bcrypted password' do
      expect(create(:user).valid_password?('password')).to be_truthy
    end

    it 'should validate imported user with sha1+salt password' do
      expect(create(:insecure_user).valid_password?('tajikistan')).to be_truthy
    end

    it 'should update an imported user to use bcrypt hashing' do
      user = create(:insecure_user)
      user.valid_password?('tajikistan')
      expect(user.hash_func).to eq("bcrypt")
    end
  end

  describe "#projects" do
    let(:user) { create(:project_owner) }

    it "should have many projects" do
      expect(user.projects).to all( be_a(Project) )
    end
  end

  describe "#user_group_memberships" do
    let(:user) { create(:user_group_member) }

    it "should have many user group members" do
      expect(user.user_group_memberships).to all( be_a(UserGroupMembership) )
    end
  end

  describe "#user_groups" do
    let(:user) { create(:user_group_member) }

    it "should be a member of many user groups" do
      expect(user.user_groups).to all( be_a(UserGroup) )
    end
  end

  describe "#collections" do
    let(:user) { create(:user_with_collections) }

    it "should have many collections" do
      expect(user.collections).to all( be_a(UserSubjectCollection) )
    end
  end
end
