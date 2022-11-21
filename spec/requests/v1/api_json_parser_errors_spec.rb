# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'handle malformed json', type: :request do
  it 'returns 400 Bad Request' do
    post '/api/classifications', params: 'this: "isn\'t json"', headers: {
      'HTTP_ACCEPT' => 'application/vnd.api+json; version=1',
      'CONTENT_TYPE' => 'application/json'
    }
    expect(response).to have_http_status(:bad_request)
  end
end
