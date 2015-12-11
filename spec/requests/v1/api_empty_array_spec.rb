require 'spec_helper'

RSpec.describe 'when an empty array is in a param', type: :request do
  include APIRequestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, owner: user) }
  let!(:workflow) { create(:workflow, project: project) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: "public project") }
  let(:url) { "/api/workflows/#{workflow.id}" }
  let!(:etag) do
    get url, nil,
      { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
       "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
    response.headers['ETag']
  end

  context "for workflows" do
    context "when a task has no answers" do
      it 'should return an empty array' do
        ups = {workflows: {
                           tasks: {
                                   interest: {
                                              type: 'single',
                                              question: "?PORQUE?",
                                              answers: []
                                             }
                                  }
                          }
              }
        put url, ups.to_json,
          "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
          "CONTENT_TYPE" => "application/json",
          "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}",
          "If-Match" => etag
        expect(json_response["workflows"][0]["tasks"]["interest"]["answers"]).to eq([])
      end
    end
  end
end
