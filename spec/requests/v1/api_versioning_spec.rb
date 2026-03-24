# frozen_string_literal: true

require 'spec_helper'

describe 'api versioning with accept headers', type: :request do
  before do
    create_list(:user, 2)
  end

  describe 'html format' do
    it 'returns a not found outcome' do
      options = { headers: { 'HTTP_ACCEPT' => 'text/html' } }
      begin
        get '/api/users', **options
        expect(response).to have_http_status(:not_found)
      rescue ActionController::RoutingError => e
        expect(e.message).to eq('Not Found')
      end
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
