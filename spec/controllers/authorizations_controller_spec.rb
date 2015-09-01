require 'spec_helper'

shared_examples "restricted scopes" do
  context 'requesting appropriate scopes' do
    it 'should return a successful status' do
      req
      expect(response.status).to eq(200)
    end

    it 'should render the approval page' do
      expect(req).to render_template(:new)
    end
  end

  context 'requesting greater scopes' do
    it 'should return unprocessable entity' do
      params['scope'] = 'public twentytwo'
      req
      expect(response.status).to eq(422)
    end
  end

  context 'requesting no scopes' do
    it 'should create a page with the apps default scopes' do
      params.delete('scope')
      req
      expect(assigns(:pre_auth).scopes).to eq(['public', 'project', 'classification'])
    end
  end
end

describe AuthorizationsController, type: :controller do
  let(:owner) { create(:user) }
  let(:params) { { "client_id" => app.uid,
                   "redirect_uri" => 'urn:ietf:wg:oauth:2.0:oob',
                   "scope" => "public project classification" } }
  let(:token_params) { params['response_type'] = 'token'; params }
  let(:code_params) { params['response_type'] = 'code'; params }

  before(:each) do
    sign_in owner
  end

  context "a grant from a first party application" do
    let!(:app) { create(:first_party_app, owner: owner) }

    it 'should skip authorization and redirect' do
      get :new, token_params
      expect(response).to redirect_to(/\A#{params[:redirect_uri]}?access_token/)
    end
  end

  context "an implicit grant by an insecure application" do
    let!(:app) { create(:application, owner: owner) }
    let(:req) { get :new, token_params }

    it_behaves_like 'restricted scopes'
  end

  context "an authorization grant by a secure application" do
    let!(:app) { create(:secure_app, owner: owner) }
    let(:req) { get :new, code_params }

    it_behaves_like 'restricted scopes'
  end

  context "an authorization grant by an insecure application" do
    let!(:app) { create(:application, owner: owner) }

    it 'should return 422 unprocessable entity' do
      get :new, code_params
      expect(response.status).to eq(422)
    end
  end
end
