require 'spec_helper'

describe "doorkeeper applications list", type: :request do
  let(:get_oauth_apps) { get oauth_applications_path }

  context "when unauthenticated" do
    before(:each) { get_oauth_apps }

    it 'should redirect to the new session page' do
      expect(response.status).to eq(302)
    end

    it 'should redirect to the new session page' do
      expect(subject).to redirect_to(new_user_session_url)
    end
  end

  context "when authenticated" do

    it 'should allow access' do
      sign_in_as_a_valid_user(:user)
      get_oauth_apps
      expect(response.status).to eq(200)
    end
  end
end
