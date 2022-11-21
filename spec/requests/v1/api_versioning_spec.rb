# frozen_string_literal: true

require 'spec_helper'

describe 'api versioning with accept headers', type: :request do
  before do
    create_list(:user, 2)
  end

  describe 'html format' do
    it 'raises a route not found error' do
      options = [{ headers: { 'HTTP_ACCEPT' => 'text/html' } }]
      expect { get '/api/users', *options }.to raise_error(ActionController::RoutingError)
    end
  end

  describe 'JSON format' do
    before do
      get '/api/users', headers: { 'HTTP_ACCEPT' => 'application/json' }
    end

    it 'responds with not found' do
      expect(response).to have_http_status(:not_found)
    end

    it 'has the error in the body response' do
      json_error = { errors: [{ message: 'Not Found' }] }.as_json
      expect(JSON.parse(response.body)).to eq(json_error)
    end
  end

  describe 'JSON-API version 1 format' do
    it 'allows access' do
      get '/api/users', headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1' }
      expect(response).to have_http_status(:ok)
    end
  end
end
