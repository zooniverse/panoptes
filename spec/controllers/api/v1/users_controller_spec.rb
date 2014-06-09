require 'spec_helper'

describe Api::V1::UsersController, type: :controller do
  let!(:users) {
    n = Array(22..30).sample
    create_list(:user, n)
  }

  before(:each) do
    default_request
  end

  shared_examples "a response" do
    it "should return the correct content type" do
      expect(response.content_type).to eq("application/vnd.api+json; version=1")
    end

    it "should include allowed attributes" do expect(json_response["users"]).to all( include("name",
                                                     "login",
                                                     "display_name",
                                                     "created_at",
                                                     "updated_at",
                                                     "credited_name",
                                                     "id") )
    end

    it "should have links to a users owned resources" do
      expect(json_response["links"]).to include("users.projects", 
                                                "users.collections", 
                                                "users.classifications",
                                                "users.subjects")
    end

    it "should have a list of users" do
      expect(json_response["users"]).to be_an(Array)
    end
  end

  describe "#index" do
    before(:each) do
      get :index
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have twenty items by default" do
      expect(json_response["users"].length).to eq(20)
    end

    it_behaves_like "a response"
  end

  describe "#show" do
    before(:each) do
      get :show, id: users.first.id
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have a single user" do
      expect(json_response["users"].length).to eq(1)
    end

    it_behaves_like "a response"
  end

  describe "#me" do
    before(:each) do 
      stub_token_with_user(users.first)
      get :me
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have a single user" do
      expect(json_response["users"].length).to eq(1)
    end

    it_behaves_like "a response"
  end

  describe "#destory" do
    before(:each) do
      delete :destroy, id: users.first.id
    end

    it "should return 204" do
      expect(response.status).to eq(204)
    end

    it "should disable the user" do
      expect(users.first.reload.inactive?).to be_truthy
    end
  end
end
