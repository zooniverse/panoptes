require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let!(:workflows){ create_list :workflow_with_subjects, 2 }
  let(:workflow){ workflows.first }
  let(:project){ workflow.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'workflows' }

  let(:api_resource_attributes){ %w(id name tasks classifications_count subjects_count created_at updated_at) }
  let(:api_resource_links){ %w(workflows.project workflows.subject_sets) }

  before(:each) do
    default_request scopes: %w(public workflow)
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
      get :show, id: workflow.id
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should return the requested workflow' do
      expect(json_response[api_resource_name].length).to eq 1
    end

    it_behaves_like 'an api response'
  end

  describe '#update' do
    it 'should be implemented'
  end

  describe '#create' do
    before(:each) do
      default_request scopes: %w(public workflow), user_id: owner.id
      params = {
        workflow: {
          name: 'Test workflow',
          tasks: [{ foo: 'bar' }, { bar: 'baz' }],
          project_id: project.id,
          grouped: true,
          prioritized: true
        }
      }
      post :create, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'should create a new workflow' do
      expect(response.status).to eq 201
      created = json_response['workflows'].first
      expect(created['name']).to eq 'Test workflow'
      expect(created['tasks']).to eq [{ 'foo' => 'bar' }, { 'bar' => 'baz' }]
    end

    it_behaves_like 'an api response'
  end

  describe '#destroy' do
    before(:each) do
      default_request scopes: %w(public workflow), user_id: owner.id
      params = {
        id: workflow.id
      }
      delete :destroy, params, { 'CONTENT_TYPE' => 'application/json' }
    end

    it 'should delete a workflow' do
      expect(response.status).to eq 204
      expect{ workflow.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
