require 'spec_helper'

describe Api::V1::CollectionsController, type: :controller do
  let!(:collections){ create_list :collection_with_subjects, 2 }
  let!(:private_collection){ create :collection_with_subjects, visibility: 'private' }
  let(:collection){ collections.first }
  let(:project){ collection.project }
  let(:owner){ collection.owner }
  let(:api_resource_name){ 'collections' }

  let(:api_resource_attributes){ %w(id name display_name created_at updated_at) }
  let(:api_resource_links){ %w(collections.project collections.owner) }

  before(:each) do
    default_request scopes: %w(public collection)
  end

  describe '#index' do
    before(:each) do
      default_request scopes: %w(public collection), user_id: owner.id
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
      default_request scopes: %w(public collection), user_id: owner.id
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
    it 'should be implemented'
  end

  describe '#create' do
    let(:created_collection_id) { created_instance_id("collections") }

    before(:each) do
      default_request scopes: %w(public collection), user_id: owner.id
      params = {
        collection: {
          name: 'Test collection',
          display_name: 'Fancy name',
          project_id: project.id
        }
      }
      post :create, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it "should return 201" do
      expect(response.status).to eq(201)
    end

    it 'should create the new collection' do
      created = Collection.find(created_collection_id)
      expect(created.name).to eq 'Test collection'
      expect(created.display_name).to eq 'Fancy name'
      expect(created.owner).to eq owner
      expect(created.project).to eq project
    end

    it "should set the Location header as per JSON-API specs" do
      id = created_collection_id
      expect(response.headers["Location"]).to eq("http://test.host/api/collections/#{id}")
    end

    it_behaves_like 'an api response'
  end

  describe '#destroy' do
    before(:each) do
      default_request scopes: %w(public collection), user_id: owner.id
      params = {
        id: collection.id
      }
      delete :destroy, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'should delete a collection' do
      expect(response.status).to eq 204
      expect{ collection.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
