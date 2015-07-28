require 'spec_helper'

describe 'api should only accept properly formatted ids', type: :request do
  include APIRequestHelpers

  let(:user) { create(:user, login: 'parrish') }

  before(:each) do
    allow_any_instance_of(Api::ApiController)
      .to receive(:doorkeeper_token)
           .and_return(token(["public", "user"], user.id))
  end

  describe 'when an id is not an integer' do
    before(:each) do
      get "/api/users/parrish", nil, { "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
    end

    it 'should return 404' do
      expect(response.status).to eq(404)
    end

    it 'should return an error message' do
      expect(JSON.parse(response.body)['errors'][0]['message']).to eq("Not Found")
    end
  end

  describe 'when an id is an integer' do
    before(:each) do
      get "/api/users/#{user.id}", nil, { "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
    end

    it 'should return 200' do
      expect(response.status).to eq(200)
    end
  end
end
