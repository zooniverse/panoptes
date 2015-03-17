require "spec_helper"

RSpec.describe "when cellect errors", type: :request do
  include APIRequestHelpers
  include CellectHelpers
  
  let(:workflow) { create(:workflow_with_subjects) }

  before(:each) do
    stub_cellect_connection
    allow(stubbed_cellect_connection).to receive(:get_subjects).twice.and_raise(StandardError)
    get "/api/subjects?sort=cellect&workflow_id=#{workflow.id}", nil, 
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
  end
  
  it 'should return 503' do
    expect(response).to have_http_status(:service_unavailable)
  end

  it 'should return a message saying cellect is down' do
    expect(json_response['errors'].first['message']).to eq('Cellect is unavailable')
  end
end
