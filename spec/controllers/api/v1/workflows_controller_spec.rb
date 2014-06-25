require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let!(:workflows){ create_list :workflow_with_subjects, 2 }
  let(:workflow){ workflows.first }
  let(:api_resource_name){ 'workflows' }

  let(:api_resource_attributes){ %w(id tasks classifications_count subjects_count created_at updated_at) }
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
end
