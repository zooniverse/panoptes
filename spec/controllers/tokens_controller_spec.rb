require 'spec_helper'

shared_context "a valid login" do
  it "it should respond with 200" do
    req
    expect(response.status).to eq(200)
  end

  it "it should return the expected response format" do
    token_response_keys = [ "access_token", "token_type", "expires_in", "scope" ]
    req
    expect(json_response).to include(*token_response_keys)
  end
end

describe TokensController, type: :controller do
  let(:owner) { create(:user)}

  context "a first party application" do
    let!(:app) { create(:first_party_app, owner: owner) }

    describe "resource owner password credentials flow" do
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
        let(:req) { post :create, valid_creds }

        it_behaves_like "a valid login"

        context "when the user has been disabled" do
          it "it should respond with 401" do
            owner.disable!
            req
            expect(response.status).to eq(401)
          end
        end
      end

      context "when supplied a valid users's devise session" do
        let(:req) do 
          @request.env['devise.mapping'] = Devise.mappings[:user]
          sign_in owner
          params.delete("client_secret")
          post :create, params
        end

        it_behaves_like "a valid login"
      end
    end
  end
end
