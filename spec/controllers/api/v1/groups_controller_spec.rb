require 'spec_helper'

describe Api::V1::GroupsController, type: :controller do
  let!(:user_groups) do
    [ create(:user_group_with_users),
      create(:user_group_with_projects),
      create(:user_group_with_collections) ]
  end

  let(:api_resource_name) { "user_groups" }
  let(:api_resource_attributes) do
    [ "id", "name", "display_name", "owner_name", "classifications_count", "created_at", "updated_at" ]
  end
  let(:api_resource_links) do
    [ "user_groups.memberships", "user_groups.users", "user_groups.projects", "user_groups.collections" ]
  end

  before(:each) do
    user = user_groups[0].users.first
    default_request(scopes: ["public", "group"], user_id: user.id)
  end

  describe "#index" do
    before(:each) do
      get :index
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have three items by default" do
      expect(json_response[api_resource_name].length).to eq(3)
    end

    it_behaves_like "an api response"
  end

  describe "#show" do
    before(:each) do
      get :show, id: user_groups.first.id
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have a single group" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it_behaves_like "an api response"
  end

  describe "#create" do
    let(:created_user_group_id) { created_instance_id("user_groups") }

    context "with valid params" do
      let!(:create_params) { { user_group: { name: "Zooniverse" } } }

      it "should create a new UserGroup" do
        expect{post :create, create_params}.to change{UserGroup.count}.by(1)
      end

      context "with caps and spaces in the group name" do
        let!(:create_params) { { user_group: { name: "Amazing Group Name" } } }

        it "should convert the owner_name#name field correctly" do
          post :create, create_params
          owner_uniq_name = UserGroup.find(created_user_group_id).owner_uniq_name
          expect(owner_uniq_name).to eq("amazing_group_name")
        end
      end

      context "with the response ready" do
        before(:each) do
          post :create, create_params
        end

        it "should return 201" do
          expect(response.status).to eq(201)
        end

        it "should set the Location header as per JSON-API specs" do
          id = created_user_group_id
          expect(response.headers["Location"]).to eq("http://test.host/api/groups/#{id}")
        end

        it "should create a project with the correct name" do
          created_id = created_user_group_id
          expect(UserGroup.find(created_id).name).to eq("zooniverse")
        end

        it "should create a the project with the correct display name" do
          created_id = created_user_group_id
          expect(UserGroup.find(created_id).display_name).to eq("Zooniverse")
        end

        it_behaves_like "an api response"
      end
    end

    context "with invalid params" do
      let!(:create_params) { { user_group: { nmae: "Zooniverse" } } }

      before(:each) do
        post :create, create_params
      end

      it "should respond with bad_request" do
        expect(response.status).to eq(422)
      end

      it "should have the validation errors in the response body" do
        message = "found unpermitted parameters: nmae"
        expect(response.body).to eq(json_error_message(message))
      end
    end
  end

  describe "#destroy" do
    let(:group) { user_groups.first }

    it "should call Activation#disable_instances! with instances to disable" do
      instances_to_disable = [group] | group.projects | group.memberships | group.collections
      expect(Activation).to receive(:disable_instances!).with(instances_to_disable)
      delete :destroy, id: group.id
    end

    it "should return 204" do
      delete :destroy, id: group.id
      expect(response.status).to eq(204)
    end

    it "should disable the group" do
      delete :destroy, id: group.id
      expect(user_groups.first.reload.inactive?).to be_truthy
    end

    context "an unauthorized user" do
      before(:each) do
        unauthorized_user = create(:user)
        stub_token(scopes: ["user"], user_id: unauthorized_user.id)
        delete :destroy, id: group.id
      end

      it "should return 403" do
        expect(response.status).to eq(403)
      end

      it "should not disable the user_group" do
        expect(group.reload.inactive?).to be_falsy
      end
    end
  end
end
