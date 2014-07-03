require 'spec_helper'

describe User, :type => :model do
  let(:user) { build(:user) }
  let(:named) { user }
  let(:unnamed) { build(:user, uri_name: nil) }
  let(:activatable) { user }
  let(:owner) { user }
  let(:owned) { build(:project, owner: user) }

  it_behaves_like "is uri nameable"
  it_behaves_like "activatable"
  it_behaves_like "is an owner"

  describe '::from_omniauth' do
    let(:auth_hash) { OmniAuth.config.mock_auth[:facebook] }

    shared_examples 'new user from omniauth' do
      let(:user_from_auth_hash) { 
        user = User.from_omniauth(auth_hash)
      }

      it 'should create a new valid user' do
        expect(user_from_auth_hash).to be_valid
      end

      it 'should create a user with the same details' do
        expect(user_from_auth_hash.email).to eq(auth_hash.info.email)
        expect(user_from_auth_hash.display_name).to eq(auth_hash.info.name)
      end

      it 'should create a user with a login' do
        expect(user_from_auth_hash.login).to eq(auth_hash.info.name.downcase.gsub(/\s/, '_'))
      end

      it 'should create a user with a provider' do
        expect(user_from_auth_hash.provider).to eq(auth_hash.provider)
      end

      it 'should not persist the user' do
        expect(user.persisted?).to be false
      end
    end

    context 'a new user with email' do
      it_behaves_like 'new user from omniauth'
    end

    context 'a user without an email' do
      let(:auth_hash) { OmniAuth.config.mock_auth[:facebook_no_email] }

      it 'should not have an email' do
        expect(User.from_omniauth(auth_hash).email).to be_nil
      end

      it_behaves_like 'new user from omniauth'
    end

    context 'an existing user' do
      let!(:omniauth_user) { create(:omniauth_user) }

      it 'should return the existing user' do
        expect(User.from_omniauth(auth_hash)).to eq(omniauth_user)
      end
    end
  end

  describe '#login' do
    it 'should validate presence' do
      expect{ User.create!(name: 't', password: 'password1', email: 'test@example.com') }.to raise_error
    end

    it 'should validate uniqueness' do
      expect{ User.create!(name: 't', login: 't', password: 'password1', email: 'test@example.com') }.to_not raise_error
      expect{ User.create!(name: 't', login: 't', password: 'password1', email: 'test2@example.com') }.to raise_error
      expect{ User.create!(name: 'T', login: 'T', password: 'password1', email: 'test3@example.com') }.to raise_error
    end
  end

  describe '#email' do
    it 'should validate case insensitive uniqueness' do
      expect{ User.create!(name: 't', login: 't', password: 'password1', email: 'test@example.com') }.to_not raise_error
      expect{ User.create!(name: 't2', login: 't2', password: 'password1', email: 'TEST@example.com') }.to raise_error
    end
  end

  describe "#password_required?" do
    it 'should require a password when creating with a new user' do
      expect{ User.create!(name: 't', login: "t", password: "password1", email: "test@example.com") }
        .to_not raise_error

      expect{ User.create!(name: 'T', login: "T", email: "test@example.com") }
        .to raise_error
    end

    it 'should not require a password when creating a user from an import' do
      expect{ User.create!({name: 't', login: "t", hash_func: 'sha1', email: "test@example.com"}, without_protection: true) }
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

    it 'should validate length of user passwords' do
      user_errors = ->(attrs){ User.new(attrs).tap{ |u| u.valid? }.errors }
      expect(user_errors.call(password: 'ab12')).to have_key :password
      expect(user_errors.call(password: 'abcd1234')).to_not have_key :password
      expect(user_errors.call(migrated_user: true, password: 'ab')).to have_key :password
      expect(user_errors.call(migrated_user: true, password: 'ab12')).to_not have_key :password
    end
  end

  describe "#active_for_authentication?" do
    let(:user) { create(:user) }

    it "should return true for an active user" do
      expect(user.active_for_authentication?).to eq(true)
    end

    it "should be false for a disabled user" do
      user.disable!
      expect(user.active_for_authentication?).to eq(false)
    end
  end

  describe "#languages" do

    context "when no languages are set" do

      it "should return an emtpy array for no set languages" do
        user = build(:user)
        expect(user.languages).to match_array([])
      end
    end
  end

  describe "#projects" do
    let(:user) { create(:project_owner) }

    it "should have many projects" do
      expect(user.projects).to all( be_a(Project) )
    end
  end

  describe "#memberships" do
    let(:user) { create(:user_group_member) }

    it "should have many user group members" do
      expect(user.memberships).to all( be_a(Membership) )
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
      expect(user.collections).to all( be_a(Collection) )
    end
  end

  describe "#subjects" do
    let(:relation_instance) { user }

    it_behaves_like "it has a subjects association"
  end

  describe "#classifications" do
    let(:relation_instance) { user }

    it_behaves_like "it has a classifications assocation"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { user }

    it_behaves_like "it has a cached counter for classifications"
  end
end
