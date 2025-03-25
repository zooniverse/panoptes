require 'spec_helper'

describe Api::ApiController, type: :controller do
  let(:user) { create(:user) }
  let!(:collection) { create(:collection, private: false) }

  before(:each) do
    allow_any_instance_of(described_class).to receive(:resource_class).and_return(Collection)
  end

  context "without doorkeeper" do
    controller do

      def index
        render json_api: { tests: [{ all: "good" },
                                   { at: "least" },
                                   { thats: "what I pretend" } ] }
      end
    end

    describe "without doorkeeper" do
      it "should return 200 without a logged in user" do
        get :index
        expect(response.status).to eq(200)
      end
    end
  end

  context "with doorkeeper" do
    controller do
      require_authentication :index, scopes: [:public]
      def index
        render json_api: { tests: [{ all: "good" },
                                   { at: "least" },
                                   { thats: "what I pretend" } ] }
      end

    end

    it "should return 401 without a logged in user" do
      get :index
      expect(response.status).to eq(401)
    end

    describe "when a user has the correct scope" do
      it "should return 200 with a logged in user" do
        default_request(scopes: ["public"], user_id: user.id)
        get :index
        expect(response.status).to eq(200)
      end
    end

    describe "when a user has an expired token" do
      let(:token) do
        create(:expired_token, scopes: ["public"].join(","), resource_owner_id: user.id)
      end

      it "should return 401" do
        get :index, params: { access_token: token.token }
        expect(response.status).to eq(401)
      end
    end

    describe "when a user has a revoked token" do
      let(:token) do
        create(:revoked_token, scopes: ["public"].join(","),
               resource_owner_id: user.id,
               use_refresh_token: true)
      end

      it "should return 401" do
        get :index, params: { access_token: token.token }
        expect(response.status).to eq(401)
      end
    end

    describe "when a user has an incorrect scope" do

      it "should return 403 with a logged in user" do
        allow(controller).to receive(:doorkeeper_token) {
          double( accessible?: true,
                  acceptable?: false,
                  includes_scope?: false,
                  resource_owner_id: user.id ) }
        get :index
        expect(response.status).to eq(403)
      end
    end
  end

  describe "when a banned user attempts to take an action" do
    let(:user) { create(:user, banned: true) }

    controller do
      def update
        render nothing: true
      end

      def create
        render nothing: true
      end

      def destroy
        render nothing: true
      end
    end

    let(:api_user) { ApiUser.new(user) }

    before(:each) do
      routes.draw do
        put "update" => "api/api#update"
        post "create" => "api/api#create"
        delete "destroy" => "api/api#destroy"
      end

      allow(controller).to receive(:api_user).and_return(api_user)
      @request.env["CONTENT_TYPE"] = "application/json"
    end

    context "create action" do
      it 'should return an empty created response' do
        post :create
        expect(response.status).to eq(201)
      end
    end

    context "update action" do
      it 'should return an empty okay response' do
        put :update
        expect(response.status).to eq(200)
      end
    end

    context "destroy action" do
      it 'should return an empty no content response' do
        delete :destroy
        expect(response.status).to eq(204)
      end
    end
  end
end
