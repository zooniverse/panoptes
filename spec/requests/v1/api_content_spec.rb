require 'spec_helper'

describe "api should only accept certain content types", type: :request do
  describe "json format" do
    it 'should allow access but return unauthorized' do
      put "/api/users/1", nil, { "CONTENT_TYPE" => "application/json; charset=utf-8",
                               "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
      expect(response.status).to eq(401)
    end
  end

  describe "json patch format" do
    it 'should allow access on PATCH requests but return unauthorized' do
      patch '/api/users/1', nil, { "CONTENT_TYPE" => "application/patch+json; charset=utf-8",
                                   "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }

      expect(response.status).to eq(401)
    end

    it 'should return unsupported media type on non-patch requests' do
      put '/api/users/1', nil, { "CONTENT_TYPE" => "application/patch+json; charset=utf-8",
                               "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }

      expect(response.status).to eq(415)
    end
  end

  describe "txt format" do 
    it 'should return unsupported media type' do
      put '/api/users/1', nil, { "CONTENT_TYPE" => "text/plain; charset=utf-8",
                               "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
      expect(response.status).to eq(415)
    end

    it 'should return an error message' do
      put '/api/users/1', nil, { "CONTENT_TYPE" => "text/plain; charset=utf-8",
                               "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
      error = {"errors" => [
        {"message" => "Only requests with Content-Type: application/json are allowed"}
      ]} 
      expect(JSON.parse(response.body)).to eq(error)
    end

    it 'should allow get requests with any format' do
      get '/api/me', nil, { "CONTENT_TYPE" => "text/plain; charset=utf-8",
                            "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
      expect(response.status).to eq(401)
    end
  end
end
