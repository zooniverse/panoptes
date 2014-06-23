require 'spec_helper'

describe Doorkeeper::TokensController, type: :controller do

  describe "resource owner password credentials flow" do
    let(:owner) { create(:user)}
    let!(:app) { create(:application, owner: owner) }
    let(:params) { { "grant_type" => "password",
                     "client_id" => app.uid,
                     "client_secret" => app.secret } }

    context "when supplying invalid user credentials" do

      it "it should respond with 401" do
        post :create, params.merge!(login: "fake_login_name", password: "sekret")
        expect(response.status).to eq(401)
      end
    end

    context "when supplying valid user credentials" do
      let(:valid_creds) { params.merge!(login: owner.login, password: owner.password) }

      it "it should respond with 200" do
        post :create, valid_creds
        expect(response.status).to eq(200)
      end

      it "it should return the expected response format" do
        token_response_keys = [ "access_token", "token_type", "expires_in", "scope" ]
        post :create, valid_creds
        json_response = JSON.parse(response.body)
        expect(json_response).to include(*token_response_keys)
      end

      context "when the user has been disabled" do

        it "it should respond with 401" do
          owner.disable!
          post :create, valid_creds
          expect(response.status).to eq(401)
        end
      end
    end
  end
end
