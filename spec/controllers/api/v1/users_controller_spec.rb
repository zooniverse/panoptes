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

  describe "#update" do
    let(:user) { users.first }

    before(:each) do
      patch :update, id: user.id, patch: patch_options
    end

    context "with a valid replace patch operation" do
      let(:new_display_name) { "Mr Creosote" }
      let(:patch_options) { %Q"[{ \"op\": \"replace\", \"path\": \"/display_name\", \"value\": \"#{new_display_name}\" }]" }

      it "should return 200 status" do
        expect(response.status).to eq(200)
      end

      it "should have updated the attribute" do
        expect(user.reload.display_name).to eq(new_display_name)
      end

      it "should have a single group" do
        expect(json_response[api_resource_name].length).to eq(1)
      end

      it_behaves_like "an api response"
    end

    context "with a an invalid patch operation" do
      let(:patch_options) { %q'[{}]' }

      it "should return an error status" do
        expect(response.status).to eq(400)
      end

      it "should return a specific error message in the response body" do
        expect(response.body).to eq("\"Error: Patch failed to apply, check patch options.\"")
      end

      it "should not updated the resource attribute" do
        prev_display_name = user.display_name
        expect(user.reload.display_name).to eq(prev_display_name)
      end
    end

    context "with and patch operation that sets a required attribute to nil" do
      let(:patch_options) { %q'[{ "op": "replace", "path": "/login", "value": "" }]' }

      it "should return a bad request status" do
        expect(response.status).to eq(400)
      end

      it "should return a specific error message in the response body" do
        expect(response.body).to eq("\"Validation failed: Login can't be blank\"")
      end

      it "should not updated the resource attribute" do
        prev_login = user.login
        expect(user.reload.login).to eq(prev_login)
      end
    end
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
