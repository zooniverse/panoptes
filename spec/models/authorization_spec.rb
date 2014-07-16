require 'spec_helper'

RSpec.describe Authorization, :type => :model do
  describe '::from_omniauth' do
    let(:auth_hash) { OmniAuth.config.mock_auth[:facebook] }
    let(:authorization_from_omniauth) { Authorization.from_omniauth(auth_hash) }

    context 'a new authorization' do
      it 'should be a valid authorization' do
        expect(authorization_from_omniauth).to be_valid
      end

      it 'should convert expires_at into a datetime' do
        expect(authorization_from_omniauth.expires_at).to be_a(Time)
      end
    end

    context 'an existing authorization with the same token' do
      let!(:auth) { create(:authorization) }
      it 'should return the authorization' do
        expect(authorization_from_omniauth.id).to eq(auth.id)
      end
    end

    context 'an existing authorization with a new token' do
      let!(:auth) { create(:authorization, token: 'token', expires_at: 1.minute.from_now) }

      it 'should return the auth with a new token' do
        authorization_from_omniauth
        auth.reload
        expect(auth.token).to_not eq('token')
        expect(auth.token).to eq(auth_hash.credentials.token)
      end

      it 'should update the expires_at time' do
        expect(authorization_from_omniauth.expires_at).to be > auth.expires_at
      end
    end
  end

  it 'should not allow a user to have multiple authorizations for the same provider' do
    user = create(:user)
    auth1 = create(:authorization, provider: 'facebook', user: user)
    auth2 = build(:authorization, provider: 'facebook', user: user)
    expect(auth2).to_not be_valid
  end

end
