require 'spec_helper'

describe Api::V1::UsersController, type: :controller do
  let!(:users) {
    n = Array(22..30).sample
    create_list(:user, n)
  }

  before(:each) do
    default_request
  end

  let(:api_resource_name) { "users" }
  let(:api_resource_attributes) do
    [ "id", "login", "display_name", "credited_name", "created_at", "updated_at" ]
  end
  let(:api_resource_links) do
    [ "users.projects", "users.collections", "users.classifications", "users.subjects" ]
  end

  describe "#index" do
    before(:each) do
      get :index
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have twenty items by default" do
      expect(json_response[api_resource_name].length).to eq(20)
    end

    it_behaves_like "an api response"
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

    it_behaves_like "an api response"
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
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it_behaves_like "an api response"
  end

  describe "#destroy" do
    let(:user) { users.first}
    let(:user_id) { user.id }

    it "should call the UserInfoScrubber with the user" do
      expect(UserInfoScrubber).to receive(:scrub_personal_info!).with(user)
      delete :destroy, id: user_id
    end

    it "should call Activation#disable_instances! with instances to disable" do
      instances_to_disable = [user] | user.projects | user.collections | user.memberships
      expect(Activation).to receive(:disable_instances!).with(instances_to_disable)
      delete :destroy, id: user_id
    end

    it "should return 204" do
      delete :destroy, id: user_id
      expect(response.status).to eq(204)
    end

    it "should disable the user" do
      delete :destroy, id: user_id
      expect(users.first.reload.inactive?).to be_truthy
    end
  end
end
