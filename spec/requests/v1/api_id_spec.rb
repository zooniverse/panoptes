# frozen_string_literal: true

require 'spec_helper'

describe 'api should only accept properly formatted ids', type: :request do
  include APIRequestHelpers

  let(:user) { create(:user, login: 'parrish') }

  before do
    allow_any_instance_of(Api::ApiController)
      .to receive(:doorkeeper_token)
      .and_return(token(%w[public user], user.id))
  end

  describe 'when an id is not an integer' do
    before do
      get '/api/users/parrish', headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1' }
    end

    it 'returns 404' do
      expect(response.status).to eq(404)
    end

    it 'returns an error message' do
      expect(JSON.parse(response.body)['errors'][0]['message']).to eq('Not Found')
    end
  end

  describe 'when an id is an integer' do
    before do
      get "/api/users/#{user.id}", headers: { 'HTTP_ACCEPT' => 'application/vnd.api+json; version=1' }
    end

    it 'returns 200' do
      expect(response.status).to eq(200)
    end
  end
end
