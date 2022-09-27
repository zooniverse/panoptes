# frozen_string_literal: true

require 'spec_helper'

describe 'api should allow conditional requests', type: :request do
  include APIRequestHelpers
  let(:user) { create(:user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: 'public project') }
  let(:project) { create(:project_with_contents, owner: user) }
  let(:url) { "/api/projects/#{project.id}" }
  let(:req) do
    get url,
        headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1',
                   'HTTP_AUTHORIZATION' => "Bearer #{access_token.token}" }
    put url, params: { projects: { name: 'different_name' } }.to_json,
             headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1',
                        'CONTENT_TYPE' => 'application/json',
                        'HTTP_AUTHORIZATION' => "Bearer #{access_token.token}",
                        'If-Match' => response.etag }
  end

  context 'when a record is locked' do
    before do
      allow_any_instance_of(Project).to receive(:lock_version).and_return(-1)
      req
    end

    it 'returns conflict' do
      expect(response).to have_http_status(:conflict)
    end
  end

  context 'when a record is not locked' do
    before do
      req
    end

    it 'returns ok' do
      expect(response).to have_http_status(:ok)
    end
  end
end
