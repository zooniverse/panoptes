require 'spec_helper'

RSpec.describe 'handle BadLinkParams errors', type: :request do
  include APIRequestHelpers
  let(:user) { create(:user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: "public project") }
  let!(:project) { create(:project, owner: user) }
  let!(:workflow) { create(:workflow, project: project) }
  let!(:subject_set) { create(:subject_set, project: project) }

  before(:each) do
    post "/api/workflows/#{workflow.id}/links/subject_sets", { subject_set_id: subject_set.id.to_s }.to_json,
         { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
           "CONTENT_TYPE" => "application/json",
           "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
  end

  it 'should return 422 when BadLinkParams error is rescued' do
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'should return a message when BadLinkParams error is rescued' do
    expect(json_response['errors'].first['message']).to match("Link relation subject_sets must match body key")
  end
end
