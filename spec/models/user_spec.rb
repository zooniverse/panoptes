require 'spec_helper'

describe User do
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
      expect(build(:user).valid_password?('password')).to be_truthy
    end

    it 'should validate imported user with sha1+salt password' do
      expect(build(:insecure_user).valid_password?('tajikistan')).to be_truthy
    end

    it 'should update an imported user to use bcrypt hashing' do
      user = build(:insecure_user)
      user.valid_password?('tajikistan')
      expect(user.hash_func).to eq("bcrypt")
    end
  end
end
