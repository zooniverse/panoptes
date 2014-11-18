require "spec_helper"

RSpec.describe Api::V1::CollectionRolesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:collection) { create(:collection, owner: authorized_user) }

  let!(:ucps) do
    create_list :user_collection_preference, 2, collection: collection,
                roles: []
  end

  let(:api_resource_name) { "collection_roles" }
  let(:api_resource_attributes) { %w(id roles) }
  let(:api_resource_links) { %w(collection_roles.user collection_roles.collection) }

  let(:scopes) { %w(public collection) }
  let(:resource) { ucps.first }
  let(:resource_class) { UserCollectionPreference }

  describe "#index" do
    let!(:private_resource) { create(:user_collection_preference) }

    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end
  
  describe "#update" do
    let(:unauthorized_user) { resource.user }
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

    let(:resource_to_update) do
      create :user_collection_preference, roles: [], collection: collection
    end

    let(:resource_to_not_update) do
      create :user_collection_preference, roles: ["collaborator"], collection: collection
    end
    
    let(:created_params) do
      {
        collection_roles: {
          roles: ["collaborator"],
          links: {
            user: resource.user.id.to_s,
            collection: resource.collection.id.to_s
          }
        }
      }
    end
    
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

    it_behaves_like "creatable or updatable"
  end
end
