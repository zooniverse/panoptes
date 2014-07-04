require 'spec_helper'

describe Api::V1::GroupsController, type: :controller do
  let!(:user_groups) do
    [ create(:user_group_with_users),
      create(:user_group_with_projects),
      create(:user_group_with_collections) ]
  end

  let(:api_resource_name) { "user_groups" }
  let(:api_resource_attributes) do
    [ "id", "display_name", "classifications_count", "created_at", "updated_at" ]
  end
  let(:api_resource_links) do
    [ "user_groups.memberships", "user_groups.users", "user_groups.projects", "user_groups.collections" ]
  end

  before(:each) do
    default_request
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

  describe "#destroy" do
    let(:group) { user_groups.first }

    it "should call Activation#disable_instances! with instances to disable" do
      instances_to_disable = [group] | group.projects | group.memberships
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
  end
end
