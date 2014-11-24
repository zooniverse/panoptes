require 'spec_helper'

shared_context "a valid login" do
  it "it should respond with 200" do
    req
    expect(response.status).to eq(200)
  end

  it "it should return the expected response format" do
    token_response_keys = [ "access_token", "token_type", "expires_in", "refresh_token", "scope" ]
    req
    expect(json_response).to include(*token_response_keys)
  end
end

describe TokensController, type: :controller do
  let(:owner) { create(:user)}

  describe "resource owner password credentials flow" do
    let(:params) { { "grant_type" => "password",
                     "client_id" => app.uid,
                     "scope" => "public project classification",
                     "client_secret" => app.secret } }

    context "a first party application" do
      let!(:app) { create(:first_party_app, owner: owner) }

      context "when supplying invalid user credentials" do
        it "it should respond with 401" do
          post :create, params.merge!(login: "fake_login_name", password: "sekret")
          expect(response.status).to eq(401)
        end
      end

      context "when supplying missing and blank application client_id" do

        it "it should respond with 422" do
          post :create, params.merge!("client_id" => '')
          expect(response.status).to eq(422)
        end

        it "it should respond with 422" do
          post :create, params.except("client_id")
          expect(response.status).to eq(422)
        end
      end

      context "when supplying valid user credentials" do
        let(:valid_creds) { params.merge!(login: owner.login, password: owner.password) }
        let(:req) { post :create, valid_creds }

        it_behaves_like "a valid login"

        context "when requesting less then or equal the apps max scope" do
          it 'should return the requested scope' do
            req
            expect(json_response['scope']).to eq(params['scope'])
          end
        end

        context "when requesting more than the allowed scope" do
          it 'should return a unprocessable entity error' do
            params['scope'] = 'public murder_one'
            req
            expect(response.status).to eq(422)
          end
        end

        context "when requesting no scope" do
          it "should return a token with the app's max scope" do
            params.delete('scope')
            req
            expect(json_response['scope']).to eq('public project classification')
          end
        end

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

    context "an insecure application" do
      let!(:app) { create(:application, owner: owner) }

      it 'should reject the token request with unprocessable entity' do
        post :create, params
        expect(response.status).to eq(422)
      end
    end

    context "a secure application" do
      let!(:app) { create(:secure_app, owner: owner) }

      it 'should reject the token request with unprocessable entity' do
        post :create, params
        expect(response.status).to eq(422)
      end
    end
  end
end
