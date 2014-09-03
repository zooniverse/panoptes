require 'spec_helper'

def get_oauth_apps
  get oauth_applications_path
end

describe "doorkeeper applications list", type: :request do

  context "when unauthenticated" do

    it 'should not allow access but return unauthorized' do
      get_oauth_apps
      expect(response.status).to eq(401)
    end
  end

  context "when authenticated as a non-adming" do

    it 'should not allow access but return forbidden' do
      sign_in_as_a_valid_user
      get_oauth_apps
      expect(response.status).to eq(403)
    end
  end

  context "when authenticated as an admin user" do

    it 'should allow access' do
      sign_in_as_a_valid_user(:admin_user)
      get_oauth_apps
      expect(response.status).to eq(200)
    end
  end
end
