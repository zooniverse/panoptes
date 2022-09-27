require 'spec_helper'

shared_examples 'cors headers' do
  let(:hashed_response_headers) { response.headers.to_h }

  it 'has the Access-Control-Allow-Origin header' do
    expect(hashed_response_headers).to include('Access-Control-Allow-Origin' => '*')
  end

  it 'has the Access-Control-Expose-Headers header' do
    expect(hashed_response_headers).to include('Access-Control-Expose-Headers')
  end

  it 'exposes the correct headers' do
    expect(
      response.headers['Access-Control-Expose-Headers']
    ).to eq('ETag, X-CSRF-Param, X-CSRF-Token')
  end

  it 'has the Access-Control-Allow-Methods header' do
    expect(hashed_response_headers).to include('Access-Control-Allow-Methods' => 'DELETE, GET, POST, OPTIONS, PUT, HEAD')
  end

  it 'has the correct Access-Control-Max-Age header' do
    expect(hashed_response_headers).to include('Access-Control-Max-Age' => '300')
  end
end

RSpec.describe "api should return CORS headers on all requests", type: :request do
  include APIRequestHelpers

  let(:user) { create(:user) }
  let(:request_headers) do
    {
      'HTTP_ACCEPT' => 'application/vnd.api+json; version=1',
      'HTTP_ORIGIN' => 'example.com'
    }
  end

  describe "non-error requests" do
    before(:each) do
      allow_any_instance_of(Api::ApiController).to receive(:doorkeeper_token).and_return(token(["public", "user"], user.id))
      get "/api/users/#{user.id}", headers: request_headers
    end

    it { expect(response).to have_http_status(:ok) }

    it_behaves_like "cors headers"
  end

  describe "4xx erro requests" do
    context "401 request" do
      before(:each) do
        delete "/api/users/#{user.id}", headers: request_headers
      end

      it { expect(response).to have_http_status(:unauthorized) }

      it_behaves_like "cors headers"
    end

    context "404 request" do
      before(:each) do
        allow_any_instance_of(Api::ApiController).to receive(:doorkeeper_token).and_return(token(["public", "user"], user.id))
        get '/api/users/asdfasdf', headers: request_headers
      end

      it { expect(response).to have_http_status(:not_found) }

      it_behaves_like "cors headers"
    end
  end
end
