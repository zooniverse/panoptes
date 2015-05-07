require 'spec_helper'

RSpec.describe ZooniverseUser, type: :model do
  it 'should not be valid without an non-case_sensitive unique email' do
    zu = create(:zooniverse_user)
    expect(build(:zooniverse_user, email: zu.email.upcase)).to_not be_valid
  end

  it 'should not be valid without an non-case_sensitive unique login' do
    zu = create(:zooniverse_user)
    expect(build(:zooniverse_user, login: zu.login.upcase)).to_not be_valid
  end

  describe "::import_users" do
    let!(:zus) { create_list(:zooniverse_user, 2) }

    context "with no arguments" do
      it 'should import all zooniverse users' do
        ZooniverseUser.import_users
        expect(User.all.map(&:display_name)).to include(*zus.map(&:login))
      end
    end

    context "with user_names" do
      it 'should only import the supplied user names' do
        ZooniverseUser.import_users([zus.first.login])
        expect(User.find_by(zooniverse_id: zus.first.id.to_s).display_name).to match(zus.first.login)
      end

      it 'should not import non-specified users' do
        expect(User.find_by(zooniverse_id: zus.last.id.to_s)).to be_nil
      end
    end
  end

  describe "::authenticate" do
    let!(:zu) { create(:zooniverse_user) }

    it 'should return the user when supplied the password of a user with a matching login' do
      expect(ZooniverseUser.authenticate(zu.login, zu.password)).to eq(zu)
    end

    it 'should return nil when no user matches' do
      expect(ZooniverseUser.authenticate("asdfasdf", zu.password)).to be_nil
    end
  end

  describe "::create_from_user" do
    let(:user) { create(:user) }

    it 'should create a ZooniverseUser from a User' do
      expect(ZooniverseUser.create_from_user(user).login).to eq(user.display_name)
    end

    it 'should set the zooniverse id of the user' do
      zu = ZooniverseUser.create_from_user(user)
      user.save!
      user.reload
      expect(user.zooniverse_id).to eq(zu.id.to_s)
    end
  end

  describe "#password=" do
    subject do
      zu = build(:zooniverse_user, password: nil)
      zu.password = 'apassword'
      zu.save!
      zu
    end

    it 'should set the password_salt' do
      expect(subject.password_salt).to_not be_nil
    end

    it 'should set the crypted_password' do
      expect(subject.crypted_password).to_not be_nil
    end
  end

  describe "#import" do
    context 'when the User has not already be imported' do
      let(:zu) { create(:zooniverse_user) }
      it 'should create a User from a Zooniverse User' do
        expect(zu.import.display_name).to eq(zu.login)
      end

      context "when the avatar is nil" do
        it 'should set the users avatar' do
          expect(zu.import.avatar.src).to match(/default_forum_avatar.png/)
        end

      end

      context "when the avatar exists" do
      let(:zu) { create(:zooniverse_user, avatar_file_name: "/test.png") }
        it 'should set the users avatar' do
          expect(zu.import.avatar.src).to match(/\/#{zu.id}\/.+\.png/)
        end
      end
    end

    context 'when the User has been imported' do
      it 'should update the User' do
        user = create(:user, migrated: true, build_zoo_user: true)
        zu = ZooniverseUser.find(user.zooniverse_id.to_i)
        new_email = "new_test_email@test.com"
        zu.update!(email: new_email)
        expect(zu.import.email).to eq(new_email)
      end
    end
  end

  describe "#authenticate" do
    let(:zu) { create(:zooniverse_user) }

    context "when password matches" do
      it 'should return itself' do
        expect(zu.authenticate(zu.password)).to eq(zu)
      end
    end

    context "when password doesn't match" do
      it 'should return nil' do
        expect(zu.authenticate("asdfasd")).to be_nil
      end
    end
  end

  describe "#set_tokens!" do
    subject do
      zu = build(:zooniverse_user, persistence_token: nil, single_access_token: nil, perishable_token: nil)
      zu.set_tokens!
      zu.save!
      zu
    end

    it 'should set the persistence token' do
      expect(subject.persistence_token).to_not be_nil
    end

    it 'should set the single access token' do
      expect(subject.single_access_token).to_not be_nil
    end

    it 'should set the perishable token' do
      expect(subject.perishable_token).to_not be_nil
    end
  end
end
