# frozen_string_literal: true

require 'spec_helper'

describe 'when a route is missing', type: :request do
  include APIRequestHelpers

  before do
    post '/api/classification', params: { classification: { something: 'test' } }.to_json,
                                headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1', 'CONTENT_TYPE' => 'application/json' }
  end

  it 'returns 404' do
    expect(response).to have_http_status(:not_found)
  end

  it 'returns a json api response' do
    expect(JSON.parse(response.body)['errors'][0]['message']).to match(/Not Found/)
  end
end
