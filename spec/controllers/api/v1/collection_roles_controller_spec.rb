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

    describe "custom owner links" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id if authorized_user
        get :index
      end

      it_behaves_like "it has custom owner links"
    end

    context "filter by user_id" do
      before(:each) do
        get :index, user_id: authorized_user.id
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

    context "a user which cannot edit the collection" do
      let(:user) { create(:user) }

      before(:each) do
        default_request scopes: scopes, user_id: user.id
        post :create, create_params
      end

      it 'should return an error code' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
