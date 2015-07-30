require 'spec_helper'

describe Api::V1::UserGroupsController, type: :controller do
  let!(:user_groups) do
    [ create(:user_group_with_users),
      create(:user_group_with_projects),
      create(:user_group_with_collections),
      create(:user_group, private: false) ]
  end

  let(:user) { user_groups[0].users.first }

  let(:api_resource_name) { "user_groups" }
  let(:api_resource_attributes) do
    [ "id", "name", "display_name", "classifications_count", "created_at", "updated_at", "type" ]
  end
  let(:api_resource_links) do
    [ "user_groups.memberships", "user_groups.users", "user_groups.projects", "user_groups.collections", "user_groups.recents" ]
  end

  let(:scopes) { %w(public group) }
  let(:resource_class) { UserGroup }
  let(:authorized_user) { user_groups.first.users.first }

  before(:each) do
    default_request(scopes: scopes, user_id: user.id)
  end

  describe "#index" do
    let(:private_resource) { user_groups[1] }
    let(:n_visible) { 2 }
    let(:resource) { user_groups[-1] }
    let(:deactivated_resource) { create(:user_group, activated_state: :inactive) }

    it_behaves_like "it only lists active resources"

    context "filtering by name" do
      it 'should return only the requested group' do
        create(:membership,
               state: :active,
               user: user,
               user_group: user_groups[1])

        get :index, name: user_groups[1].name

        expect(json_response["user_groups"]).to all( include("name" => user_groups[1].name) )
      end
    end

    context "no filters" do
      it_behaves_like "is indexable"
    end

    it_behaves_like "filter by display_name"
  end

  describe "#update" do
    let(:resource) { user_groups.first }
    let(:test_attr) { :display_name}
    let(:test_attr_value) { "A-Different-Name" }
    let(:update_params) do
      {
        user_groups: {
          display_name: "A-Different-Name",
        }
      }
    end

    it_behaves_like "is updatable"
  end

  describe "#show" do
    let(:resource) { user_groups.first }

    context "includes customized urls" do
      before(:each) do
        get :show, id: resource.id
      end

      it 'should include a url for projects' do
        projects_link = json_response['links']['user_groups.projects']['href']
        expect(projects_link).to eq("/projects?owner={user_groups.name}")
      end

      it 'should include a url for collections' do
        collections_link = json_response['links']['user_groups.collections']['href']
        expect(collections_link).to eq("/collections?owner={user_groups.name}")
      end
    end

    it_behaves_like "is showable"
  end

  describe "#create" do
    let(:test_attr) { :name }
    let(:test_attr_value) { "Zooniverse" }
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
        membership = authorized_user.memberships.where(user_group: group).first
        expect(membership.roles).to include("group_admin")
      end
    end

    describe "when only a name is provided" do
      it "should set the display name" do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, { user_groups: { name: "GalaxyZoo" }}

        group = UserGroup.find(created_instance_id("user_groups"))
        expect(group.display_name).to eq("GalaxyZoo")
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

  describe "#update_links" do
    let(:new_user) { create(:user) }
    let(:resource) { user_groups.first }
    let(:new_membership) { Membership.where(user: new_user, user_group: resource).first }
    let(:test_relation) { :users }
    let(:test_relation_ids) { [ new_user.id.to_s ] }
    let(:resource_id) { :user_group_id }

    context "created membership" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        post :update_links, user_group_id: resource.id, users: [ new_user.id.to_s ], link_relation: "users"
      end

      it 'should give the user a group_member role' do
        expect(new_membership.roles).to eq(%w(group_member))
      end
    end

    it_behaves_like "supports update_links"
  end

  describe "#destroy_links" do
    let(:resource) { user_groups.first }
    let(:test_relation) { :users }
    let(:resource_id) { :user_group_id }
    let(:test_relation_ids) { [ resource.users.first.id.to_s ] }

    context "setting membership to inactive" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        delete :destroy_links, user_group_id: resource.id, link_ids: test_relation_ids.join(','), link_relation: "users"
      end

      it 'should give the delete user membership to inactive' do
        expect(Membership.where(user_id: test_relation_ids,
                                user_group_id: resource.id)).to all( be_inactive )
      end
    end
  end

  describe "#recents" do
    let(:resource) { user_groups.first }
    let(:resource_key) { :user_group }
    let(:resource_key_id) { :user_group_id }

    it_behaves_like "has recents"
  end
end
