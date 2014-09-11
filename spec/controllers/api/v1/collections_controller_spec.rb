require 'spec_helper'

describe Api::V1::CollectionsController, type: :controller do
  let!(:collections){ create_list :collection_with_subjects, 2 }
  let!(:private_collection){ create :collection_with_subjects, visible_to: ['collaborator'] }
  let(:collection){ collections.first }
  let(:project){ collection.project }
  let(:owner){ collection.owner }
  let(:api_resource_name){ 'collections' }

  let(:api_resource_attributes){ %w(id name display_name created_at updated_at) }
  let(:api_resource_links){ %w(collections.project collections.owner) }

  let(:scopes) { %w(public collection) }
  let(:authorized_user) { owner }
  let(:resource_class) { Collection }

  before(:each) do
    default_request scopes: scopes
  end

  describe '#index' do
    before(:each) do
      default_request scopes: scopes, user_id: owner.id
      get :index
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should have 2 items by default' do
      expect(json_response[api_resource_name].length).to eq 2
    end

    it 'should not include nonvisible collections' do
      collection_ids = json_response['collections'].collect{ |h| h['id'].to_i }
      expect(collection_ids).to_not include private_collection.id
    end

    it_behaves_like 'an api response'
  end

  describe '#show' do
    before(:each) do
      default_request scopes: scopes, user_id: owner.id
      get :show, id: collection.id
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should return the requested collection' do
      expect(json_response[api_resource_name].length).to eq 1
    end

    it_behaves_like 'an api response'
  end

  describe '#update' do
    let(:subjects) { create_list(:subject, 4) }
    let(:resource) { collection }
    let(:test_attr) { :name }
    let(:test_attr_value) { "Tested Collection" }
    let(:test_relation) { :subjects }
    let(:test_relation_ids) { subjects.map(&:id) }
    let(:update_params) do
      { collections: {
                      name: "Tested Collection",
                      links: {
                              subjects: subjects.map(&:id).map(&:to_s)
                             }
                     }
      }
    end

    it_behaves_like "is updatable"
  end

  describe '#create' do
    let(:test_attr) { :name }
    let(:test_attr_value) { 'Test collection' }
    let(:create_params) do
      {
       collections: {
                     name: 'Test collection',
                     display_name: 'Fancy name',
                     project_id: project.id
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
