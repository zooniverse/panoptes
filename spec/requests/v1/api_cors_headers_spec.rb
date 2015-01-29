require 'spec_helper'

shared_examples 'cors headers' do
  it 'should have Access-Control-Allow-Origin header' do
    expect(response.headers).to include('Access-Control-Allow-Origin' => 'example.com')
  end

  it 'should have Access-Control-Expose-Headers header' do
    expect(response.headers).to include('Access-Control-Expose-Headers')
  end

  it 'should have Access-Control-Allow-Methods header' do
    expect(response.headers).to include('Access-Control-Allow-Methods' => "DELETE, GET, POST, OPTIONS, PUT")
  end
end

RSpec.describe "api should return CORS headers on all requests", type: :request do
  include APIRequestHelpers

  let(:user) { create(:user) }
  
  describe "non-error requests" do
    before(:each) do
      allow_any_instance_of(Api::ApiController).to receive(:doorkeeper_token).and_return(token(["public", "user"], user.id))
      get "/api/users/#{user.id}", nil, { "HTTP_ACCEPT" => "application/vnd.api+json; version=1", "HTTP_ORIGIN" => "example.com" }
    end

    it { expect(response).to have_http_status(:ok) } 

    it_behaves_like "cors headers"
  end

  describe "4xx erro requests" do
    context "401 request" do
      before(:each) do
        delete "/api/users/#{user.id}", nil, { "HTTP_ACCEPT" => "application/vnd.api+json; version=1", "HTTP_ORIGIN" => "example.com" }
      end

      it { expect(response).to have_http_status(:unauthorized) }
    
      it_behaves_like "cors headers"
    end

    context "404 request" do
      before(:each) do
        allow_any_instance_of(Api::ApiController).to receive(:doorkeeper_token).and_return(token(["public", "user"], user.id))
        get "/api/users/asdfasdf", nil, { "HTTP_ACCEPT" => "application/vnd.api+json; version=1", "HTTP_ORIGIN" => "example.com" }
      end

      it { expect(response).to have_http_status(:not_found) }
      
      it_behaves_like "cors headers"
    end
  end
end
