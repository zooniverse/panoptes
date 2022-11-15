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

  describe 'testing allowed origins on controlled paths' do
    context 'with domains that match the allow regex' do
      it 'returns the Access-Control-Allow-Origin response header' do
        get '/users/sign_in', headers: {
          'HTTP_ACCEPT' => 'application/json',
          'HTTP_ORIGIN' => 'http://localhost:3000'
        }
        expect(response.headers.to_h).to include('Access-Control-Expose-Headers')
      end
    end

    context 'with domains that do not match the allow regex' do
      it 'does not return the Access-Control-Allow-Origin response header' do
        get '/users/sign_in', headers: {
          'HTTP_ACCEPT' => 'application/json',
          'HTTP_ORIGIN' => 'http://example.com'
        }
        expect(response.headers.to_h).not_to include('Access-Control-Expose-Headers')
      end
    end

    context 'with multiple domains in the rejected origins blocklist' do
      let(:source_origin) { 'http://localhost:3000' }

      it 'compares the origin for each block list entry and deals with whitespacing issues' do
        stub_const('Panoptes::CORS_ORIGIN_HOST_REJECTIONS', %w[panoptes-uploads-staging.zooniverse.org panoptes-uploads.zooniverse.org])
        allow(URI).to receive(:parse).and_call_original
        get '/users/sign_in', headers: {
          'HTTP_ACCEPT' => 'application/json',
          'HTTP_ORIGIN' => source_origin
        }
        expect(URI).to have_received(:parse).with(source_origin).twice
      end
    end

    context 'with domains match the rejected origins blocklist' do
      before do
        # allow all zooniverse subdomains - test the block list in isolation
        stub_const('Panoptes::CORS_ORIGINS_REGEX', %r{https?://[a-z0-9-]+\.zooniverse\.org$})
        # explicitly block the test domain
        stub_const('Panoptes::CORS_ORIGIN_HOST_REJECTIONS', ['panoptes-uploads.zooniverse.org'])
      end

      it 'does not have the Access-Control-Allow-Origin response header' do
        get '/users/sign_in', headers: {
          'HTTP_ACCEPT' => 'application/json',
          'HTTP_ORIGIN' => 'https://panoptessdfdsfd-uploads.zooniverse.org'
        }
        expect(response.headers.to_h).not_to include('Access-Control-Expose-Headers')
      end
    end
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
