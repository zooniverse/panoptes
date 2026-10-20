require "spec_helper"

RSpec.describe Api::V1::CollectionRolesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:collection) { create(:collection, owner: authorized_user) }

  let!(:acls) do
    create_list :access_control_list_with_user_group, 2, resource: collection,
                roles: ["viewer"]
  end

  let(:api_resource_name) { "collection_roles" }
  let(:api_resource_attributes) { %w(id roles) }
  let(:api_resource_links) { %w(collection_roles.collection) }

  let(:scopes) { %w(public collection) }
  let(:resource) { acls.first }
  let(:resource_class) { AccessControlList }

  describe "#index" do
    let!(:private_resource) { create(:access_control_list, resource: create(:collection, private: true)) }
    let(:n_visible) { 3 }

    it_behaves_like "is indexable"

    describe "custom owner links" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
        get :index
      end

      it_behaves_like "it has custom owner links"
    end

    context "filter by user_id" do
      before(:each) do
        get :index, params: { user_id: authorized_user.id }
      end

      it 'should only reutrn roles belonging to the user' do
        owner_links = json_response[api_resource_name][0]["links"]["owner"]
        expect(owner_links).to include("type" => "users", "id" => authorized_user.id.to_s)
      end

      it 'should only return one role' do
        expect(json_response[api_resource_name].length).to eq(1)
      end
    end
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe '#update' do
    let(:unauthorized_user) { create(:user) }
    let(:test_attr) { :roles }
    let(:test_attr_value) { %w(collaborator) }

    let(:update_params) do
      { collection_roles: { roles: ["collaborator"] } }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :roles }
    let(:test_attr_value) { ["collaborator"] }

    let(:create_params) do
      {
        collection_roles: {
          roles: ["collaborator"],
          links: {
            user: create(:user).id.to_s,
            collection: collection.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"

    context "a user which cannot edit the collection" do
      let(:user) { create(:user) }

      before(:each) do
        default_request scopes: scopes, user_id: user.id
        post :create, params: create_params
      end

      it 'should return an error code' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end

  context 'when a user is added to a collection' do
    let(:user) do
      create(:user) do |user|
        create :access_control_list, user_group: user.identity_group, resource: collection
      end
    end

    before do
      default_request scopes: scopes, user_id: authorized_user.id
      allow(UserAddedToCollectionMailerWorker).to receive(:perform_async)
    end

    it 'enqueues mailer worker' do

      other_user = create(:user)
      params = {
        collection_roles: {
          roles: ['collaborator'],
          links: {
            user: other_user.id.to_s,
            collection: collection.id.to_s
          }
        }
      }
      post :create, params: params

      expect(UserAddedToCollectionMailerWorker).to have_received(:perform_async).with(other_user.id, collection.id, ['collaborator']).once
    end

    it 'enqueues mailer worker if user role is updated to include a new role' do
      params = {
        collection_roles: {
          roles: %w[collaborator viewer]
        }
      }
      
      put :update, params: params.merge(id: user.user_groups.first.access_control_lists.first)

      expect(UserAddedToCollectionMailerWorker).to have_received(:perform_async).with(user.id, collection.id, %w[collaborator viewer]).once
    end

    it 'does not call the mailer if user role is removed from collection' do
      params = {
        collection_roles: {
          roles: []
        }
      }
      put :update, params: params.merge(id: user.user_groups.first.access_control_lists.first)
      expect(UserAddedToCollectionMailerWorker).not_to have_received(:perform_async)
    end
  end
end
