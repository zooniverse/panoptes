# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V1::AggregationsController, type: :controller do
  let(:api_resource_name) { 'aggregations' }
  let(:api_resource_attributes) { %w[id created_at updated_at uuid task_id status] }
  let(:api_resource_links) { %w[aggregations.workflow] }

  let(:scopes) { %w[public workflow] }
  let(:resource_class) { Aggregation }

  describe '#index' do
    let(:workflow) { create(:workflow) }
    let!(:aggregations) { create_list(:aggregation, 2, workflow: workflow) }
    let!(:private_resource) { create(:aggregation) }
    let(:authorized_user) { workflow.project.owner }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable'
  end

  describe '#show' do
    let(:resource) { create(:aggregation) }
    let(:authorized_user) { resource.workflow.project.owner }

    it_behaves_like 'is showable'
  end

  describe 'create' do
    let(:workflow) { create(:workflow) }
    let(:authorized_user) { workflow.project.owner }
    let(:test_attr) { :workflow_id }
    let(:test_attr_value) { workflow.id }
    let(:fake_response) {double }
    let(:mock_agg) { instance_double(AggregationClient) }

    let(:create_params) do
      { aggregations:
          {
            links: {
              user: authorized_user.id.to_s,
              workflow: workflow.id.to_s
            }
          }
      }
    end

    before do
      allow(AggregationClient).to receive(:new).and_return(mock_agg)
      allow(fake_response).to receive(:body).and_return({'task_id': 'asdf-1234-asdf'})
      allow(mock_agg).to receive(:send_aggregation_request).and_return(fake_response)
      default_request scopes: scopes, user_id: authorized_user.id
    end

    it_behaves_like 'is creatable'

    it 'makes a request to the aggregation service' do
      post :create, params: create_params
      expect(mock_agg).to have_received(:send_aggregation_request)
    end

    it 'stores the task_id from the client response' do
      post :create, params: create_params
      expect(Aggregation.first.task_id).to eq('asdf-1234-asdf')
    end
  end

  describe '#update' do
    let(:workflow) { create(:workflow) }
    let(:authorized_user) { resource.workflow.project.owner }
    let(:resource) { create(:aggregation, workflow: workflow) }
    let(:test_attr) { :uuid }
    let(:test_attr_value) { '1234-asdf-1234' }

    let(:update_params) do
      { aggregations:
          {
            uuid: '1234-asdf-1234',
            status: 'completed'
          }
      }
    end

    it_behaves_like 'is updatable'
  end
end
