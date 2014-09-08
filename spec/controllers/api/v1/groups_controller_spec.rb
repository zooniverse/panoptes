require 'spec_helper'

describe Api::V1::GroupsController, type: :controller do
  let!(:user_groups) do
    [ create(:user_group_with_users),
     create(:user_group_with_projects),
     create(:user_group_with_collections) ]
  end

  let(:user) { user_groups[0].users.first }

  let(:api_resource_name) { "user_groups" }
  let(:api_resource_attributes) do
    [ "id", "name", "display_name", "owner_name", "classifications_count", "created_at", "updated_at" ]
  end
  let(:api_resource_links) do
    [ "user_groups.memberships", "user_groups.users", "user_groups.projects", "user_groups.collections" ]
  end

  let(:scopes) { %w(public group) }

  before(:each) do
    default_request(scopes: scopes, user_id: user.id)
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
    let(:authorized_user) { create(:user) }
    let(:resource_class) { UserGroup }
    let(:test_attr) { :name }
    let(:test_attr_value) { "zooniverse" }
    let(:resource_name) { 'groups' }
    let(:create_params) { { user_groups: { name: "Zooniverse" } } }

    it_behaves_like "is creatable"

    describe "default member" do
      let(:group_id) { created_instance_id('user_groups') }
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end
      
      it "should make a the creating user a member" do
        membership = Membership.where(user_group_id: group_id).first
        expect(authorized_user.memberships).to include(membership)
      end

      it "should amke the creating user a group admin" do
        group = UserGroup.find(group_id)
        expect(authorized_user.roles_for(group)).to include("group_admin")
      end
    end
  end

  describe "#destroy" do
    let(:resource) { user_groups.first }
    let(:authorized_user) { resource.users.first }
    let(:instances_to_disable) do
      [resource] |
        resource.projects |
        resource.memberships |
        resource.collections
    end

    it_behaves_like "is deactivatable"

  end
end
