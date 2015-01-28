require "spec_helper"

RSpec.describe Api::V1::CollectionRolesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:collection) { create(:collection, owner: authorized_user) }

  let!(:acls) do
    create_list :access_control_list, 2, resource: collection,
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
  end

  describe "#show" do
    it_behaves_like "is showable"
  end
  
  describe "#update" do
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
  end
end
