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
  let(:resource_class) { UserGroup }
  let(:authorized_user) { user_groups.first.users.first }

  before(:each) do
    default_request(scopes: scopes, user_id: user.id)
  end

  describe "#index" do
    let(:private_resource) { user_groups[1] }
    let(:n_visible) { 1 }
    
    it_behaves_like "is indexable"
  end
  
  describe "#update" do
    let(:resource) { user_groups.first }
    let(:test_attr) { :display_name}
    let(:test_attr_value) { "A Different Name" }
    let(:update_params) do
      {
       user_groups: {
                     display_name: "A Different Name",
                    }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#show" do
    let(:resource) { user_groups.first }
    
    it_behaves_like "is showable"
  end

  describe "#create" do
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

      it "should make the creating user a group admin" do
        group = UserGroup.find(group_id)
        expect(authorized_user.roles_for(group)).to include("group_admin")
      end
    end
  end

  describe "#destroy" do
    let(:resource) { user_groups.first }
    let(:instances_to_disable) do
      [resource] |
        resource.projects |
        resource.memberships |
        resource.collections
    end

    it_behaves_like "is deactivatable"
  end
end
