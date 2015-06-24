require 'spec_helper'

describe Api::V1::CollectionsController, type: :controller do
  let(:owner) { create(:user) }
  let!(:collections) { create_list :collection_with_subjects, 2, owner: owner }
  let(:collection) { collections.first }
  let(:project) { collection.project }
  let(:api_resource_name) { 'collections' }

  let(:api_resource_attributes) { %w(id name display_name created_at updated_at) }
  let(:api_resource_links) { %w(collections.project collections.owner collections.collection_roles collections.subjects) }

  let(:scopes) { %w(public collection) }
  let(:authorized_user) { owner }
  let(:resource_class) { Collection }

  before(:each) do
    default_request scopes: scopes
  end

  describe '#index' do
    let(:filterable_resources) { collections }
    let(:expected_filtered_ids) { [ filterable_resources.first.id.to_s ] }
    let!(:private_resource) do
      create :collection_with_subjects, private: true
    end

    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
    it_behaves_like "it has custom owner links"
    it_behaves_like 'has many filterable', :subjects
  end

  describe '#show' do
    let(:resource) { collection }

    it_behaves_like "is showable"
  end

  describe '#update' do
    let(:subjects) { create_list(:subject, 4) }
    let(:resource) { collection }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "Tested Collection" }
    let(:test_relation) { :subjects }
    let(:test_relation_ids) { subjects.map(&:id) }
    let(:update_params) do
      {
       collections: {
                     display_name: "Tested Collection",
                     private: false,
                     links: {
                             subjects: subjects.map(&:id).map(&:to_s)
                            }
                    }
      }
    end


    it_behaves_like "is updatable"
    it_behaves_like "has updatable links"
  end

  describe '#create' do
    let(:test_attr) { :name }
    let(:test_attr_value) { 'test__collection' }
    let(:create_params) do
      {
       collections: {
                     name: 'test__collection',
                     display_name: 'Fancy name',
                     private: false,
                     links: { project: project.id }
                    }
      }
    end

    it_behaves_like 'is creatable'
  end

  describe '#destroy' do
    let(:resource) { collection }

    it_behaves_like "is destructable"
  end
end
