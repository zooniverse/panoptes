require 'spec_helper'

describe SessionsController, type: :controller do
  let!(:users) { create_list(:user, 2) }
  let(:user) { users.first }

  context "using json", :zoo_home_user do
    before(:each) do
      request.env["HTTP_ACCEPT"] = "application/json"
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

      it 'should ignore login case' do
        expect(controller).to receive(:sign_in)
        post :create, user: {login: user.login.upcase, password: user.password}
      end
    end

    describe "#destroy" do
      context "a signed in user" do
        before(:each) do
          request.env['devise.user'] = user
          sign_in user
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

    describe "#new" do
      let(:providers) { %w(facebook) }

      before(:each) do
        get :new
      end

      it 'should return 200' do
        expect(response.status).to eq(200)
      end

      it 'should return a json response of login routes' do
        expect(json_response).to include('login', *providers)
      end

      it 'should return the url for each omniauth provider' do
        expect(json_response['facebook']).to eq('/users/auth/facebook')
      end
    end
  end
end
