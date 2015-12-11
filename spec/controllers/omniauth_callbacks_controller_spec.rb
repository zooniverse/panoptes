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

  it 'should redirect to a user editor if the created user is not valid'
  it 'should redirect to a user editor if the created user is not unique'
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

  describe '#gplus' do
    before(:each) do
      request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:gplus]
    end

    let(:provider) { 'gplus' }
    let(:req) { get :gplus }

    it_behaves_like 'an omniauth callback'
  end
end
