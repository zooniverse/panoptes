require 'spec_helper'

describe OmniauthCallbacksController, type: :controller do
  describe '#facebook' do
    before(:each) do
      request.env['devise.mapping'] = Devise.mappings[:user]
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    end
    
    it 'should create a user from an omniauth hash if one doesn\'t exist' do
      get :facebook
      expect(subject.current_user).to be_valid
      expect(subject.current_user).to be_persisted
    end

    it 'should return a user from an omniauth hash if it does it exist' do
      ou = create(:omniauth_user)
      get :facebook
      expect(subject.current_user).to eq(ou)
    end

    it 'should sign in the user' do
      get :facebook
      expect(subject.current_user).to_not be_nil
    end

    it 'should redirect to omniauth.origin' do
      request.env['omniauth.origin'] = 'http://google.com'
      get :facebook
      expect(response.status).to be(302)
      expect(response).to redirect_to 'http://google.com'
    end

    it 'should redirect to http://zooniverse.org if no omniauth.orgin' do
      get :facebook
      expect(response.status).to be(302)
      expect(response).to redirect_to 'https://zooniverse.org/'
    end

    it 'should redirect to a user editor if the created user is not valid'
  end

end
