require "spec_helper"

describe ApplicationsController, type: :controller do
  describe "#create" do
    it 'should set the owner of the application' do
      user = create(:user, admin: true)
      sign_in user
      post :create, application: { name: "test app", redirect_uri: "https://test.example.com" }
      expect(Doorkeeper::Application.first.owner).to eq(user)
    end
  end
end
