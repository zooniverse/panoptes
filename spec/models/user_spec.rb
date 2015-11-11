# -*- coding: utf-8 -*-
require 'spec_helper'

describe User, type: :model do
  let(:user) { create(:user) }
  let(:activatable) { user }
  let(:owner) { user }
  let(:owned) { create(:project, owner: user.identity_group) }

  it_behaves_like "activatable"
  it_behaves_like "is an owner"

  describe "links" do
    it "should allow membership links to any user" do
      expect(User).to link_to(Membership).with_scope(:all)
    end

    it "should allow user_gruop links to any user" do
      expect(User).to link_to(UserGroup).with_scope(:all)
    end
  end

  describe '::from_omniauth' do
    let(:auth_hash) { OmniAuth.config.mock_auth[:facebook] }

    shared_examples 'new user from omniauth' do
      let(:user_from_auth_hash) do
        user = User.from_omniauth(auth_hash)
      end

      it 'should create a new valid user' do
        expect(user_from_auth_hash).to be_valid
      end

      it 'should create a user with the same details' do
        expect(user_from_auth_hash.email).to eq(auth_hash.info.email)
      end

      it 'should create a user with a login' do
        expect(user_from_auth_hash.login).to eq(auth_hash.info.name.gsub(/\s/, '_'))
      end

      it 'should create a user with a authorization' do
        expect(user_from_auth_hash.authorizations).to all( be_an(Authorization) )
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

    context 'an invalid user' do
      it 'should raise an exception' do
        create(:user, email: 'examplar@example.com')
        auth_hash = OmniAuth.config.mock_auth[:gplus]
        expect{ User.from_omniauth(auth_hash) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "::user_from_unsubscribe_token" do

    it "should find the user from the token" do
      found_user = User.user_from_unsubscribe_token(user.unsubscribe_token)
      expect(found_user.id).to eq(user.id)
    end

    it "should not return a user for a non-matching signature" do
      expect(User.user_from_unsubscribe_token("bluirhkj")).to be_nil
    end
  end

  describe '::send_reset_password_instructions' do
    context 'when the user exists' do
      let(:user) { create(:user) }

      it 'sends a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).once
        User.send_reset_password_instructions(email: user.email)
      end

      it 'returns the user' do
        returned_user = User.send_reset_password_instructions(email: user.email)
        expect(returned_user).to eq(user)
      end
    end

    context 'when the user is disabled' do
      let(:user) { create(:user).tap(&:disable!) }

      it 'does not send a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).never
        User.send_reset_password_instructions(email: user.email)
      end

      it 'returns the user' do
        returned_user = User.send_reset_password_instructions(email: user.email)
        expect(returned_user).to eq(user)
      end
    end

    context 'when the user has no email' do
      let(:user) { build(:user, email: nil) }

      it 'does not send a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).never
        User.send_reset_password_instructions(email: user.email)
      end

      it 'returns an unpersisted user' do
        returned_user = User.send_reset_password_instructions(email: user.email)
        expect(returned_user).not_to be_persisted
      end
    end

    context 'when the user cannot be found' do
      it 'does not send a password reset' do
        expect_any_instance_of(User).to receive(:send_reset_password_instructions).never
        User.send_reset_password_instructions(email: 'unknown@example.com')
      end

      it 'returns an unpersisted user' do
        returned_user = User.send_reset_password_instructions(email: 'unknown@example.com')
        expect(returned_user).not_to be_persisted
      end
    end
  end

  describe "::find_by_lower_login" do

    it "should find the user by the login" do
      user = create(:user)
      expect(User.find_by_lower_login(user.login.upcase).id).to eq(user.id)
    end

    context "when no user exits" do
      it "should not find the user by the login" do
        expect(User.find_by_lower_login("missing-User")).to be_nil
      end
    end
  end

  describe "#signup_project" do
    let(:project) { create(:project) }

    it "should not find any associated project" do
      expect(user.signup_project).to be_nil
    end

    context "when the project_id is set" do
      let!(:user) { create(:user, project_id: project.id) }

      it "should find the associated project" do
        expect(user.signup_project).to eq(project)
      end
    end
  end

  describe '#display_name' do
    let(:user) { build(:user) }

    it 'should validate presence', :aggregate_failures do
      user.display_name = ""
      expect(user.valid?).to be_falsy
      expect(user.errors[:display_name]).to include("can't be blank")
    end

    it 'should allow duplicate display names' do
      user.save
      expect {
        create(:user, display_name: user.display_name)
      }.not_to raise_error
    end
  end

  describe '#login' do
    let(:user) { build(:user, migrated: true) }

    it 'should validate presence' do
      user.login = ""
      expect(user).to_not be_valid
    end

    it 'should not have whitespace' do
      user.login = " asdf asdf"
      expect(user).to_not be_valid
    end

    it 'should not have non alpha characters' do
      user.login = "asdf!fdsa"
      expect(user).to_not be_valid
    end

    it 'should allow dashes and underscores' do
      user.login = "abc-def_123"
      expect(user).to be_valid
    end

    it 'should not enfore a minimum length' do
      expect(build(:user, login: "1")).to be_valid
    end

    it 'should have non-blank error' do
      user = build(:user, login: "")
      user.valid?
      expect(user.errors[:login]).to include("can't be blank")
    end

    it 'should validate uniqueness to enable filtering by the display name' do
      login = 'Mista_Bob_Dobalina'
      aggregate_failures "testing different cases" do
        expect{ create(:user, login: login) }.not_to raise_error
        expect{
          create(:user, login: login.upcase, email: 'test2@example.com')
        }.to raise_error(ActiveRecord::RecordInvalid)
        expect{
          create(:user, login: login.downcase, email: 'test3@example.com')
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it "should have the correct case-insensitive uniqueness error" do
      user = create(:user)
      dup_user = build(:user, login: user.login.upcase)
      dup_user.valid?
      expect(dup_user.errors[:login]).to include("has already been taken")
    end

    it 'should constrain database uniqueness' do
      user = create :user
      dup_user = create :user

      expect {
        dup_user.update_attribute 'login', user.login.upcase
      }.to raise_error ActiveRecord::RecordNotUnique
    end
  end

  describe '#email' do

    context "when a user is setup" do
      let(:user) { create(:user, email: 'test@example.com') }

      it 'should raise an error trying to save a duplicate' do
        expect{ create(:user, email: user.email.upcase) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should validate case insensitive uniqueness' do
        dup = build(:user, email: user.email.upcase)
        dup.valid?
        expect(dup.errors[:email]).to include("has already been taken")
      end

      it 'should constrain database uniqueness' do
        user = create :user
        dup_user = create :user

        expect {
          dup_user.update_attribute 'email', user.email
        }.to raise_error ActiveRecord::RecordNotUnique
      end
    end

    context "when a user is disabled and has no email" do
      subject { build(:user, email: nil, activated_state: :inactive) }

      it { is_expected.to be_valid }
    end
  end

  describe '#valid_email' do
    let(:user) { build(:user, email: 'isitvalid@example.com') }

    it 'should set the valid_email field to true' do
      expect(user.valid_email).to be_truthy
    end

    describe "setting the field to nil" do
      before(:each) do
        user.valid_email = nil
      end

      it 'should not be valid' do
        expect(user.valid?).to be_falsey
      end

      it 'should have the correct error message' do
        user.valid?
        expect(user.errors[:valid_email]).to include("must be true or false")
      end
    end
  end

  describe "#build_identity_group" do
    let(:user) { build(:user, build_group: false) }

    context "when a user has a valid login" do
      before(:each) do
        user.build_identity_group
        user.save!
        user.reload
      end

      it 'should a new membership with identity set to true' do
        expect(user.identity_membership.identity).to eq(true)
      end

      it 'should have a group with the same name as the user login' do
        expect(user.identity_group.name).to eq(user.login)
      end

      it 'should raise error if a user has an identity group' do
        user = create(:user)
        expect{ user.build_identity_group }.to raise_error(StandardError, "Identity Group Exists")
      end
    end

    context "when a user_group with the same name in different case exists" do
      let!(:user_group) { create(:user_group, name: user.login.upcase) }

      it "should not be valid" do
        expect do
          user.build_identity_group
          user.save!
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "should have the correct error message on the identity_group attribute" do
        user.build_identity_group
        user.valid?
        expect(user.errors[:"identity_group.display_name"]).to include("has already been taken")
      end
    end

    context "when the identity group is missing" do

      it "should not be valid" do
        expect(user.valid?).to be_falsy
      end

      it "should have the correct error message on the identity_group association" do
        user.valid?
        expect(user.errors[:identity_group]).to include("can't be blank")
      end
    end
  end

  describe "#password_required?" do
    it 'should require a password when creating with a new user' do
      aggregate_failures "different cases" do
        expect{ create(:user, password: "password1") }.not_to raise_error
        expect{ create(:user, password: nil) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    it 'should not require a password when creating a user from an import' do
      attrs = {login: "Mr.T", hash_func: 'sha1', email: "test@example.com"}
      expect do
        User.create!(attrs) do |u|
          u.build_identity_group
        end
      end.to_not raise_error
    end
  end

  describe "#valid_password?" do
    it 'should validate user with bcrypted password' do
      expect(create(:user).valid_password?('password')).to be_truthy
    end

    it 'should validate length of user passwords' do
      user_errors = ->(attrs){ User.new(attrs).tap{ |u| u.valid? }.errors }
      expect(user_errors.call(password: 'ab12')).to have_key :password
      expect(user_errors.call(password: 'abcd1234')).to_not have_key :password
      expect(user_errors.call(migrated: true, password: 'ab')).to have_key :password
      expect(user_errors.call(migrated: true, password: 'ab12')).to_not have_key :password
    end

    context "with the old sha1 hashing alg" do
      let(:user) do
        create(:insecure_user) do |u|
          u.hash_func = 'sha1'
          u.unsubscribe_token = nil
        end
      end

      it 'should validate imported user with sha1+salt password' do
        expect(user.valid_password?('tajikistan')).to be_truthy
      end

      it 'should not validate an imported user with an invalid password' do
        expect(user.valid_password?('nottheirpassword')).to be_falsey
      end

      it 'should update an imported user to use bcrypt hashing' do
        user.valid_password?('tajikistan')
        expect(user.hash_func).to eq("bcrypt")
      end

      it 'should add the unsubscribe token' do
        user.valid_password?('tajikistan')
        expect(user.unsubscribe_token).to_not be_nil
      end
    end
  end

  describe "#admin" do
    let(:user) { build(:user) }

    it "should be false by default" do
      expect(user.admin).to be false
    end
  end

  describe "#active_for_authentication?" do
    let(:user) { create(:user) }

    it "should call update_ouroboros_created on the model" do
      expect(user).to receive(:update_ouroboros_created)
      expect(user).not_to receive(:save)
      user.active_for_authentication?
    end

    it "should return true for an active user" do
      expect(user.active_for_authentication?).to eq(true)
    end

    it "should be false for a disabled user" do
      user.disable!
      expect(user.active_for_authentication?).to eq(false)
    end

    context "when the user was created by ouroboros" do
      let(:user) do
        User.skip_callback :validation, :before, :update_ouroboros_created
        u = build(:ouroboros_created_user)
        u.save(validate: false)
        User.set_callback :validation, :before, :update_ouroboros_created
        u
      end

      it "should update the model and be valid for auth" do
        aggregate_failures "active for auth" do
          expect(user).to receive(:update_ouroboros_created).twice.and_call_original
          expect(user).to receive(:build_identity_group).and_call_original
          expect(user).to receive(:setup_unsubscribe_token).and_call_original
          expect(user).to receive(:save).and_call_original
          expect(user.active_for_authentication?).to be true
          expect(user.reload.ouroboros_created).to be false
        end
      end
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

  describe "#classifications" do
    let(:relation_instance) { user }

    it_behaves_like "it has a classifications assocation"
  end

  describe "#classifcations_count" do
    let(:relation_instance) { user }

    it_behaves_like "it has a cached counter for classifications"
  end

  describe "::memberships_for" do
    let(:user) { create(:user_group_member) }
    let(:query_sql) { user.memberships_for(action, test_class).to_sql }
    let(:test_class) { Project }
    let(:action) { :update }

    context "supplied class" do
      it 'should query for editor roles for the supplied class' do
        expect(query_sql).to match(/project_editor/)
      end
    end

    context "no class" do
      let(:test_class) { nil }
      it 'should not add additional roles' do
        expect(query_sql).to_not match(/editor/)
      end
    end

    context "action is show" do
      let(:action) { :show }

      it 'should query for group_admin' do
        expect(query_sql).to match(/group_admin/)
      end

      it 'should query for group_member' do
        expect(query_sql).to match(/group_member/)
      end
    end

    context "action is index" do
      let(:action) { :index }

      it 'should query for group_admin' do
        expect(query_sql).to match(/group_admin/)
      end

      it 'should query for group_member' do
        expect(query_sql).to match(/group_member/)
      end
    end

    context "action is not show or index" do
      it 'should query for group_admin' do
        expect(query_sql).to match(/group_admin/)
      end

      it 'should not query for group member' do
        expect(query_sql).to_not match(/group_member/)
      end
    end
  end

  describe "::scope_for" do
    let(:ouroboros_user) do
      User.skip_callback :validation, :before, :update_ouroboros_created
      u = build(:user, activated_state: 0, ouroboros_created: true, build_group: false)
      u.save(validate: false)
      User.set_callback :validation, :before, :update_ouroboros_created
      u
    end
    let(:users) do
      [ create(:user, activated_state: 0),
        create(:user, activated_state: 0),
        ouroboros_user,
        create(:user, activated_state: 1) ]
    end

    let(:actor) { ApiUser.new(users.first) }

    context "action is show" do
      it 'should return the active users and non ouroboros_created users' do
        expect(User.scope_for(:show, actor)).to match_array(users.values_at(0,1))
      end
    end

    context "action is index" do
      it 'should return the active users and non ouroboros_created users' do
        expect(User.scope_for(:show, actor)).to match_array(users.values_at(0,1))
      end
    end

    context "action is destroy or update" do
      it 'should only return the acting user' do
        expect(User.scope_for(:destroy, actor)).to match_array(users.first)
      end
    end
  end

  describe "has_finished?" do
    let(:user) { create(:user) }
    subject { user.has_finished?(workflow) }

    context 'when the user has classified all subjects in a workflow' do
      let(:workflow) do
        workflow = create(:workflow_with_subjects)
        ids = workflow.subject_sets.flat_map(&:subjects).map(&:id)
        create(:user_seen_subject, user: user, workflow: workflow, subject_ids: ids)
        workflow
      end

      it { is_expected.to be true }
    end

    context 'when the user not finished classifying a workflow' do
      let(:workflow) do
        workflow = create(:workflow_with_subjects)
        create(:user_seen_subject, user: user, workflow: workflow, subject_ids: [])
        workflow
      end

      it { is_expected.to be false }
    end
  end

  describe "#password" do
    it "should set a user's hash_func to bcrypt" do
      u = build(:insecure_user)
      u.password = 'newpassword'
      expect(u.hash_func).to eq('bcrypt')
    end
  end

  describe "#uploaded_subjects" do
    it 'should list the subjects a user has uploaded' do
      uploader = create(:user_with_uploaded_subjects)
      expect(uploader.uploaded_subjects).to all( be_a(Subject) )
    end
  end

  describe "#uploaded_subjects_count" do
    it 'should have a count of the subjects a user has uploaded' do
      uploader = create(:user_with_uploaded_subjects)
      expect(uploader.uploaded_subjects_count).to eq(2)
    end
  end

  describe "#update_ouroboros_created" do
    let(:user) do
      build(:ouroboros_created_user, login: "NOT ALLOWED")
    end

    it 'should set login from display_name' do
      user.update_ouroboros_created
      expect(user.login).to eq(described_class.sanitize_login(user.display_name))
    end

    it 'should build an identity group' do
      user.update_ouroboros_created
      user.save!
      user.reload
      expect(user.identity_group).to be_valid
    end

    it 'should run on validation' do
      expect(user).to be_valid
    end

    context "when the login is all unicode" do

      it "should use the zooniverse id for login field instead of leaving it blank" do
        non_ascii = "ẉơŕƌé"
        User.skip_callback :validation, :before, :update_ouroboros_created
        dup_user = build(:ouroboros_created_user, display_name: non_ascii, login: non_ascii)
        dup_user.save(validate: false)
        User.set_callback :validation, :before, :update_ouroboros_created
        aggregate_failures "dup user" do
          expect(dup_user).to be_valid
          expect(dup_user.login).to eq("panoptes-#{dup_user.id}")
        end
      end
    end

    context "when the ouroboros created user has a clashing sanitized login" do
      let(:dup_user) do
        build(:ouroboros_created_user, display_name: "#{user.login}é")
      end

      before(:each) { user.save }

      it "should append a suffix to the sanitized login" do
        dup_user.valid?
        aggregate_failures "dup user" do
          expect(dup_user).to be_valid
          expect(dup_user.login).to eq("#{user.login}-1")
        end
      end

      context "when it can't find a non-clashing sanitized login" do

        it "should time out after a set number of tries" do
          allow(User).to receive(:find_by_lower_login).and_return(user)
          dup_user.valid?
          expect(dup_user.login).to eq("#{user.login}-20")
        end
      end

      context "when validating a saved ouroboros created user" do

        it "should not append a suffix to the login" do
          prev_login = user.login
          user.update_column(:ouroboros_created, true)
          user.valid?
          expect(user.login).to eq(prev_login)
        end
      end
    end
  end

  describe '#set_zooniverse_id' do
    let(:user){ create :user }
    subject{ user.zooniverse_id }
    it{ is_expected.to eql "panoptes-#{ user.id }" }
  end

  describe "#unsubscribe_token" do

    it "should not build one automatically on build" do
      expect(build(:user).unsubscribe_token).to be_nil
    end

    it "should build one automatically on create" do
      expect(user.unsubscribe_token).to_not be_nil
    end

    it "should not be valid with a duplicate" do
      allow_any_instance_of(User).to receive(:unsubscribe_token).and_return(user.unsubscribe_token)
      aggregate_failures "error messages" do
        user = build(:user)
        expect(user.valid?).to be_falsey
        expect(user.errors[:unsubscribe_token]).to include("has already been taken")
      end
    end
  end

  describe "#send_welcome_email after_create callback" do
    let(:user) { build(:user) }

    it "should send the welcome email" do
      expect(user).to receive(:send_welcome_email).once
      user.save!
    end

    it "should queue the worker with the user id" do
      allow(UserWelcomeMailerWorker).to receive :perform_async
      user.save!
      expect(UserWelcomeMailerWorker).to have_received(:perform_async).with(user.id, nil).ordered
    end

    context "when the user has a project id" do
      let!(:user) { build(:user, project_id: 1) }

      it "should queue the worker with the user id and project id" do
        allow(UserWelcomeMailerWorker).to receive :perform_async
        user.save!
        expect(UserWelcomeMailerWorker).to have_received(:perform_async).with(user.id, 1).ordered
      end
    end

    context "when the user is created via a migration" do
      let!(:user) { build(:user, migrated: true) }

      it "should not queue the worker with the user id" do
        expect(UserWelcomeMailerWorker).not_to receive(:perform_async)
        user.save!
      end
    end
  end

  describe "#set_ouroboros_api_key" do
    it 'should set the key on creation' do
      user = create(:user, api_key: nil)
      expect(user.api_key).to_not be_nil
    end
  end

  describe '#subject_limit' do
    context 'the user model has a null limit' do
      it 'should return the Panotpes.max_subjects value' do
        user = create(:user)
        expect(user.subject_limit).to eq(Panoptes.max_subjects)
      end
    end

    context 'the user model has a defined limit' do
      it 'should return that limit' do
        user = create(:user, subject_limit: 10)
        expect(user.subject_limit).to eq(10)
      end
    end
  end

  describe '#uploaded_subjects_count' do

    context 'the user has no uploaded subject' do
      it 'should return 0' do
        user = create(:user)
        expect(user.uploaded_subjects_count).to eq(0)
      end
    end

    context 'the user has uploaded subject' do
      it 'should return 1' do
        user = create(:user)
        create(:subject, uploader: user)
        expect(user.uploaded_subjects_count).to eq(1)
      end
    end
  end

  describe "#sync_identity_group" do
    it 'should set the identity group login if the user login changes' do
      user.login = "test"
      user.save!
      user.reload
      expect(user.identity_group.name).to eq("test")
    end

    it 'should set the identity group display_name if the user display_name changes' do
      user.display_name = "test"
      user.save!
      user.reload
      expect(user.identity_group.display_name).to eq("test")
    end
  end
end
