require 'spec_helper'


describe Api::ApiController, type: :controller do

  describe "without doorkeeper" do
    controller do
      def index
        render json_api: {tests: [{all: "good"},
                                  {at: "least"},
                                  {thats: "what I pretend"}]}
      end
    end
    it "should return 200 without a logged in user" do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "with doorkeeper" do
    controller do
      doorkeeper_for :index, scopes: [:public]

      def index
        render json_api: {tests: [{all: "good"},
                                  {at: "least"},
                                  {thats: "what I pretend"}]}
      end
    end

    it "should return 401 without a logged in user" do
      get :index
      expect(response.status).to eq(401)
    end
  end
end
