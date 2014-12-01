require 'spec_helper'

def setup_controller(api_controller)
  api_controller.controller do
    yield(self) if block_given?

    def index
      render json_api: { tests: [{ all: "good" },
                                 { at: "least" },
                                 { thats: "what I pretend" } ] }
    end
  end
end

describe Api::ApiController, type: :controller do
  let(:user) { create(:user) }

  describe "without doorkeeper" do
    setup_controller(self)

    it "should return 200 without a logged in user" do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "with doorkeeper" do
    setup_controller(self) { |controller| controller.doorkeeper_for :index, scopes: [:public] }

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
        get :index, access_token: token.token
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
        get :index, access_token: token.token
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

  describe "authenticated with doorkeeper but unauthorized for the action" do
    controller do
      doorkeeper_for :index, scopes: [:public]
      def index
        resource = User.find(params[:id])
        api_user.do(:show).to(resource).call do 
          render json_api: { tests: [ { all: "good" }, { at: "least" }, { thats: "what I pretend" } ] }
        end
      end
    end

    it "should return 403 with a logged in user" do
      default_request(scopes: ["public"], user_id: user.id)
      allow_any_instance_of(User).to receive(:can_show?).and_return(false)
      get :index, id: user.id
      expect(response.status).to eq(403)
    end
  end

  describe "#current_language" do
    controller do
      def index
        render json_api: current_languages
      end
    end

    before(:each) do
      user = create(:user_with_languages)
      default_request(user_id: user.id)
      get :index, language: 'es'
    end

    it 'should include langauge param as the first language' do
      expect(json_response.first).to eq('es')
    end

    it 'should include the user\'s default languages after the lang param' do
      expect(json_response[1..-1]).to include('en', 'fr-ca')
    end

    it 'should include Accept-Language(s) after the user languages' do
      expect(json_response[-3..-1]).to include('zh', 'zh-tw', 'fr-fr')
    end
  end

  describe "default access control" do
    controller do
      def update
        render nothing: true
      end

      def destroy
        render nothing: true
      end

      def create
        render nothing: true
      end

      def update_links
        render nothing: true
      end

      def destroy_links
        render nothing: true
      end

      def resource_sym
        :collections
      end

      def resource_class
        Collection
      end
    end

    let(:api_user) { ApiUser.new(user) }
    let(:collection) { create(:collection, owner: user) }
    
    before(:each) do
      routes.draw do
        put "update" => "api/api#update"
        post "create" => "api/api#create"
        delete "destroy" => "api/api#destroy"
        post "update_links" => "api/api#update_links"
        delete "destroy_links" => "api/api#destroy_links"
      end

      allow(controller).to receive(:controlled_resource).and_return(collection)
      allow(controller).to receive(:api_user).and_return(api_user)
      allow(controller).to receive(:current_actor).and_return(api_user)
      @request.env["CONTENT_TYPE"] = "application/json"
    end

    context "put #update request" do
      it 'should call can_update? on the requested collection' do
        expect(collection).to receive(:can_update?).with(api_user)
        put :update, id: collection.id
      end
    end

    context "delete #destroy request" do
      it 'should call can_destroy? on the requested collection' do
        expect(collection).to receive(:can_destroy?).with(api_user)
        delete :destroy, id: collection.id
      end
    end

    context "post #create request" do
      it 'should call can_create? on the Collection class' do
        allow(controller).to receive(:controlled_resource).and_return(Collection)
        expect(Collection).to receive(:can_create?).with(api_user)
        post :create
      end
    end

    context "post #update_links request" do
      it 'should call can_update? on the requested collection' do
        expect(collection).to receive(:can_update?).with(api_user)
        post :update_links, id: collection.id
      end
    end

    context "delete #destroy_links request" do
      it 'should call can_update? on the requested collection' do
        expect(collection).to receive(:can_update?).with(api_user)
        delete :destroy_links, id: collection.id
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
