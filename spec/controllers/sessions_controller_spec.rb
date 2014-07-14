require 'spec_helper'

describe SessionsController, type: :controller do
  let!(:users) { create_list(:user, 2) }
  let(:user) { users.first }

  context "using json" do
    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/vnd.api+json"
      request.env["CONTENT_TYPE"] = "application/json"
      request.env["devise.mapping"] = Devise.mappings[:user]
    end

    describe "#create" do
      it "should respond with the user object" do
        post :create, user: {login: user.login, password: user.password}
        expect(json_response).to include("users")
      end

      it "should respond with a 200" do
        post :create, user: {login: user.login, password: user.password}
        expect(response.status).to eq(200)
      end

      it "should sign in the user" do
        expect(controller).to receive(:sign_in)
        post :create, user: {login: user.login, password: user.password}
      end
    end

    describe "#destroy" do
      context "a signed in user" do
        before(:each) do
          request.env['devise.user'] = user
        end

        it 'should return no-content' do
          delete :destroy 
          expect(response.status).to eq(204)
        end

        it 'should sign out the user' do
          expect(controller).to receive(:sign_out)
          delete :destroy
        end
      end
    end
  end
end
