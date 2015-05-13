require 'spec_helper'

RSpec.describe Api::V1::CollectionPreferencesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:collection) { create(:collection) }

  let!(:ucps) do
    create_list :user_collection_preference, 2, user: authorized_user,
      preferences: { "display" => "grid" }
  end

  let(:api_resource_name) { 'collection_preferences' }
  let(:api_resource_attributes) { %w(id preferences) }
  let(:api_resource_links) { %w(collection_preferences.user collection_preferences.collection) }

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
    let(:unauthorized_user) { create(:user) }
    let(:test_attr) { :preferences }
    let(:test_attr_value) { { "display" => "list" } }

    let(:update_params) do
      { collection_preferences: { preferences: { display: "list" } } }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :preferences }
    let(:test_attr_value) { { "display" => "list" } }
    let(:create_params) do
      {
        collection_preferences: {
          preferences: { display: "list" },
          links: {
            collection: collection.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"
  end
end
