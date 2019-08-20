require 'spec_helper'

shared_examples "an omniauth callback" do
  it 'should create a user from an omniauth hash if one doesn\'t exist' do
    req
    expect(subject.current_user).to be_valid
    expect(subject.current_user).to be_persisted
  end

  it 'should return a user from an omniauth hash if it does it exist' do
    ou = create(:authorization, provider: provider).user
    req
    expect(subject.current_user).to eq(ou)
  end

  it 'should sign in the user' do
    req
    expect(subject.current_user).to_not be_nil
  end

  it 'should redirect to omniauth.origin' do
    request.env['omniauth.origin'] = 'http://google.com'
    req
    expect(response.status).to be(302)
    expect(response).to redirect_to 'http://google.com'
  end

  it 'should redirect to http://zooniverse.org if no omniauth.orgin' do
    req
    expect(response.status).to be(302)
    expect(response).to redirect_to 'https://zooniverse.org/'
  end

  it 'should show an error when created user is invalid' do
    user = create(:user)
    request.env['omniauth.auth']['info']['email'] = user.email
    req
  end

  context "with an already logged in user" do
    let(:user) { create(:user) }

    it 'should not log the provider user in' do
      sign_in user
      expect(User).not_to receive(:from_omniauth)
      req
      expect(subject.current_user).to eq(user)
    end
  end
end

describe OmniauthCallbacksController, type: :controller do
  before(:each) do
    request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe '#facebook' do
    before(:each) do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:facebook]
    end

    let(:provider) { 'facebook' }
    let(:req) { get :facebook }

    it_behaves_like 'an omniauth callback'
  end

  describe '#google_oauth2' do
    before(:each) do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google_oauth2]
    end

    let(:provider) { 'google_oauth2' }
    let(:req) { get :google_oauth2 }

    it_behaves_like 'an omniauth callback'
  end
end
