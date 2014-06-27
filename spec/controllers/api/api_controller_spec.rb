require 'spec_helper'

def setup_controller(api_controller)
  api_controller.controller do
    yield(self) if block_given?

    def index
      render json_api: { tests: [ { all: "good" }, { at: "least" }, { thats: "what I pretend" } ] }
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

    describe "when a user has an incorrect scope" do

      it "should return 403 with a logged in user" do
        allow(controller).to receive(:doorkeeper_token) { double( accessible?: true,
                                                                  acceptable?: false,
                                                                  includes_scope?: false ) }
        get :index
        expect(response.status).to eq(403)
      end
    end
  end

  describe "authenticated with doorkeeper but unauthorized for the action" do
    controller do
      doorkeeper_for :index, scopes: [:public]
      def index
        authorize User.find(params[:id]), :read?
        render json_api: { tests: [ { all: "good" }, { at: "least" }, { thats: "what I pretend" } ] }
      end
    end

    it "should return 403 with a logged in user" do
      default_request(scopes: ["public"], user_id: user.id)
      UserPolicy.any_instance.stub(:read?).and_return(false)
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
      default_request(user_id: create(:user))
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
end
