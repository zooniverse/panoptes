# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::UserGroupsController, type: :controller do
  let!(:user_groups) do
    [create(:user_group_with_users),
     create(:user_group_with_projects),
     create(:user_group_with_collections),
     create(:user_group, private: false)]
  end

  let(:user) { user_groups[0].users.first }

  let(:api_resource_name) { 'user_groups' }
  let(:api_resource_attributes) do
    %w[id name display_name classifications_count created_at updated_at type]
  end
  let(:api_resource_links) do
    ['user_groups.memberships', 'user_groups.users', 'user_groups.projects', 'user_groups.collections', 'user_groups.recents']
  end

  let(:scopes) { %w[public group] }
  let(:resource_class) { UserGroup }
  let(:authorized_user) { user_groups.first.users.first }

  before do
    default_request(scopes: scopes, user_id: user.id)
  end

  describe '#index' do
    let(:private_resource) { user_groups[1] }
    let(:n_visible) { 2 }
    let(:resource) { user_groups[-1] }
    let(:deactivated_resource) { create(:user_group, activated_state: :inactive) }

    it_behaves_like 'it only lists active resources'

    context 'when filtering by name' do
      it 'returns only the requested group' do
        create(:membership,
               state: :active,
               user: user,
               user_group: user_groups[1])

        get :index, params: { name: user_groups[1].name }

        expect(json_response['user_groups']).to all(include('name' => user_groups[1].name))
      end
    end

    describe 'search' do
      let(:user_group_with_uniq_name) { create(:user_group, private: false, display_name: 'My Unique Group')}

      before do
        # force an update of all user_groups to set the tsv column
        user_group_with_uniq_name.reload
        user_groups.each(&:reload)
      end

      it 'returns the user_group with exact matched display_name' do
        get :index, params: { search: user_group_with_uniq_name.display_name }
        expect(json_response[api_resource_name].length).to eq(1)
        expect(json_response[api_resource_name][0]['id']).to eq(user_group_with_uniq_name.id.to_s)
      end

      it 'returns no user_groups if search is less than 3 chars and no exact match' do
        get :index, params: { search: 'my' }
        expect(json_response[api_resource_name].length).to eq(0)
      end

      it 'does a full text search against display_name when no exact match' do
        get :index, params: { search: 'my uniq' }
        expect(json_response[api_resource_name].length).to eq(1)
        expect(json_response[api_resource_name][0]['id']).to eq(user_group_with_uniq_name.id.to_s)
      end

      it 'does a full text search against display_name on public and accessible user_groups' do
        get :index, params: { search: 'group' }
        # returns user_group_with_users, user_group_with_uniq_name, the public user_group
        expect(json_response[api_resource_name].length).to eq(3)
      end

      describe 'as admin' do
        it 'does a full text search against display_name on private and public user_groups' do
          admin_user = create(:user, admin: true)
          default_request scopes: scopes, user_id: admin_user.id
          get :index, params: { search: 'group', admin: true }
          # returns all 5 user groups
          expect(json_response[api_resource_name].length).to eq(5)
        end
      end
    end

    context 'with no filters' do
      it_behaves_like 'is indexable'
    end

    it_behaves_like 'filter by display_name'
  end

  describe '#update' do
    let(:resource) { user_groups.first }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { 'A-Different-Name' }
    let(:update_params) do
      {
        user_groups: {
          display_name: 'A-Different-Name'
        }
      }
    end

    it_behaves_like 'is updatable'

    describe 'updating stats_visibility' do
      let(:params) {
        {
          id: resource.id,
          user_groups: {
            display_name: 'A-Different-Name',
            stats_visibility: 'public_agg_only'
          }
        }
      }

      describe 'as group_admin' do
        it 'updates stats_visibility' do
          default_request scopes: scopes, user_id: authorized_user.id
          put :update, params: params
          expect(response.status).to eq(200)

          group = UserGroup.find(resource.id)
          expect(group.stats_visibility).to eq('public_agg_only')
        end

        it 'does not update user_group if invalid stats_visibility' do
          default_request scopes: scopes, user_id: authorized_user.id
          user_groups = {
            display_name: 'A-Different-Name',
            stats_visibility: 'fake_stats_visibility'
          }
          params[:user_groups] = user_groups
          put :update, params: params
          expect(response.status).to eq(400)
        end
      end

      describe 'as admin' do
        it 'updates user_group_stats_visibility' do
          admin_user = create(:user, admin: true)
          default_request scopes: scopes, user_id: admin_user.id
          params[:admin] = true
          put :update, params: params
          expect(response.status).to eq(200)
        end
      end

      describe 'as group_member' do
        it 'does not update user_group stats_visibility' do
          group_member_user = create(:user)
          create(:membership, user: group_member_user, user_group: resource, roles: ['group_member'])
          default_request scopes: scopes, user_id: group_member_user.id
          put :update, params: params
          expect(response.status).to eq(404)
        end
      end
    end
  end

  describe '#show' do
    let(:resource) { user_groups.first }

    context 'when includes customized urls' do
      before do
        get :show, params: { id: resource.id }
      end

      it 'includes a url for projects' do
        projects_link = json_response['links']['user_groups.projects']['href']
        expect(projects_link).to eq('/projects?owner={user_groups.name}')
      end

      it 'includes a url for collections' do
        collections_link = json_response['links']['user_groups.collections']['href']
        expect(collections_link).to eq('/collections?owner={user_groups.name}')
      end
    end

    it_behaves_like 'is showable'
  end

  describe '#create' do
    let(:test_attr) { :name }
    let(:test_attr_value) { 'Zooniverse' }
    let(:create_params) { { user_groups: { name: 'Zooniverse' } } }

    it_behaves_like 'is creatable'

    describe 'default member' do
      let(:group_id) { created_instance_id('user_groups') }

      before do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, params: create_params
      end

      it 'makes a the creating user a member' do
        membership = Membership.where(user_group_id: group_id).first
        expect(authorized_user.memberships).to include(membership)
      end

      it 'makes the creating user a group admin' do
        group = UserGroup.find(group_id)
        membership = authorized_user.memberships.where(user_group: group).first
        expect(membership.roles).to include('group_admin')
      end
    end

    describe 'setting stats_visibility' do
      describe 'as group_admin' do
        it 'sets the stats_visiblity when sending in stats_visiblity as string' do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, params: { user_groups: { name: 'GalaxyZoo', stats_visibility: 'public_agg_show_ind_if_member' } }
          expect(response.status).to eq(201)
          group = UserGroup.find(created_instance_id('user_groups'))

          expect(group.stats_visibility).to eq('public_agg_show_ind_if_member')
        end

        it 'sets the stats_visibility when sending related integer corresponding to visibility level' do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, params: { user_groups: { name: 'GalaxyZoo', stats_visibility: 3 } }
          expect(response.status).to eq(201)

          # see app/models/user_group.rb L22-L40 for explanations of stats_visibliity levels
          group = UserGroup.find(created_instance_id('user_groups'))
          expect(group.stats_visibility).to eq('public_agg_show_ind_if_member')
        end

        it 'does not create group if stats_visibility is invalid' do
          default_request scopes: scopes, user_id: authorized_user.id
          post :create, params: { user_groups: { name: 'GalaxyZoo', stats_visibility: 7 } }
          expect(response.status).to eq(400)
        end
      end
    end

    describe 'when only a name is provided' do
      it 'sets the display name' do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, params: { user_groups: { name: 'GalaxyZoo' } }

        group = UserGroup.find(created_instance_id('user_groups'))
        expect(group.display_name).to eq('GalaxyZoo')
      end
    end
  end

  describe '#destroy' do
    let(:resource) { user_groups.first }
    let(:instances_to_disable) do
      [resource] |
        resource.projects |
        resource.memberships |
        resource.collections
    end

    it_behaves_like 'is deactivatable'
  end

  describe '#update_links' do
    let(:new_user) { create(:user) }
    let(:resource) { user_groups.first }
    let(:new_membership) { Membership.where(user: new_user, user_group: resource).first }
    let(:test_relation) { :users }
    let(:test_relation_ids) { [new_user.id.to_s] }
    let(:resource_id) { :user_group_id }

    context 'when created membership' do
      before do
        default_request scopes: scopes, user_id: authorized_user.id
        post :update_links, params: { user_group_id: resource.id, users: [new_user.id.to_s], link_relation: 'users' }
      end

      it 'gives the user a group_member role' do
        expect(new_membership.roles).to eq(%w[group_member])
      end
    end

    it_behaves_like 'supports update_links'
  end

  describe '#destroy_links' do
    let(:resource) { user_groups.first }
    let(:test_relation) { :users }
    let(:resource_id) { :user_group_id }
    let(:test_relation_ids) { [resource.users.first.id.to_s] }

    context 'when setting membership to inactive' do
      before do
        default_request scopes: scopes, user_id: authorized_user.id
        delete :destroy_links, params:  { user_group_id: resource.id, link_ids: test_relation_ids.join(','), link_relation: 'users' }
      end

      it 'gives the delete user membership to inactive' do
        expect(Membership.where(user_id: test_relation_ids,
                                user_group_id: resource.id)).to all(be_inactive)
      end
    end
  end

  describe '#recents' do
    let(:resource) { user_groups.first }
    let(:resource_key) { :user_group }
    let(:resource_key_id) { :user_group_id }

    it_behaves_like 'has recents'
  end
end
