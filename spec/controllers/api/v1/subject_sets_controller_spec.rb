require 'spec_helper'

describe Api::V1::SubjectSetsController, type: :controller do
  let!(:subject_sets){ create_list :subject_set_with_subjects, 2 }
  let(:subject_set){ subject_sets.first }
  let(:project){ subject_set.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'subject_sets' }

  let(:api_resource_attributes){ %w(id name set_member_subjects_count created_at updated_at) }
  let(:api_resource_links){ %w(subject_sets.project subject_sets.workflows) }

  before(:each) do
    default_request scopes: %w(public subject_set)
  end

  describe '#index' do
    before(:each){ get :index }

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should have 2 items by default' do
      expect(json_response[api_resource_name].length).to eq 2
    end

    it_behaves_like 'an api response'
  end

  describe '#show' do
    before(:each) do
      get :show, id: subject_set.id
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should return the requested subject_set' do
      expect(json_response[api_resource_name].length).to eq 1
    end

    it_behaves_like 'an api response'
  end

  describe '#update' do
    it 'should be implemented'
  end

  describe '#create' do
    let(:created_subject_set_id) { created_instance_id("subject_sets") }

    before(:each) do
      default_request scopes: %w(public subject_set), user_id: owner.id
      params = {
        subject_set: {
          name: 'Test subject set',
          project_id: project.id
        }
      }
      post :create, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it "should return 201" do
      expect(response.status).to eq(201)
    end

    it 'should create the new subject set' do
      created = SubjectSet.find(created_subject_set_id)
      expect(created.name).to eq 'Test subject set'
    end

    it "should set the Location header as per JSON-API specs" do
      id = created_subject_set_id
      expect(response.headers["Location"]).to eq("http://test.host/api/subject_sets/#{id}")
    end

    it_behaves_like 'an api response'
  end

  describe '#destroy' do
    before(:each) do
      default_request scopes: %w(public subject_set), user_id: owner.id
      params = {
        id: subject_set.id
      }
      delete :destroy, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'should delete a subject set' do
      expect(response.status).to eq 204
      expect{ subject_set.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
