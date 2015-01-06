require 'spec_helper'

def request_headers(header)
  { "CONTENT_TYPE" => header }.merge(default_accept)
end

def default_accept
  { "HTTP_ACCEPT" => "application/vnd.api+json; version=1" } end

def json_content_type_headers
  request_headers("application/json; charset=utf-8")
end

def json_patch_type_headers
  request_headers("application/patch+json; charset=utf-8")
end

def text_type_headers
  request_headers("text/plain; charset=utf-8")
end

def json_api_type_headers
  request_headers("application/vnd.api+json; version=1; charset=utf-8")
end

describe "api should only accept certain content types", type: :request do

  describe "json format" do
    it 'should allow access but return unauthorized' do
      put "/api/users/1", nil, json_content_type_headers
      expect(response.status).to eq(401)
    end

    describe "classifications#create with invalid POST params" do
      let(:params) { { classification: [ { value: [ { x: 734.16 } ] } ] } }

      before(:each) do
        post "/api/classifications/", params, json_content_type_headers
      end

      it 'should respond with a bad_request stauts' do
        expect(response.status).to eq(400)
      end

      it 'should provide an error message in the response body' do
        error_message_prefix = "There was a problem in the JSON you submitted:"
        error_message_suffix = "unexpected token at 'classification[][value][][x]=734.16'"
        expect(response.body).to include(error_message_prefix)
        expect(response.body).to include(error_message_suffix)
      end
    end
  end

  describe 'json api format' do
    it 'should allow access but return unauthorized' do
      put "/api/users/1", nil, json_api_type_headers
      expect(response.status).to eq(401)
    end
  end

  describe "json patch format" do
    it 'should return not implemented on patch requests' do
      patch '/api/users/1', nil, json_patch_type_headers
      expect(response.status).to eq(501)
    end

    it 'should return unsupported media type on non-patch requests' do
      put '/api/users/1', nil, json_patch_type_headers
      expect(response.status).to eq(415)
    end
  end

  describe "txt format" do
    it 'should return unsupported media type' do
      put '/api/users/1', nil, text_type_headers
      expect(response.status).to eq(415)
    end

    it 'should return an error message' do
      put '/api/users/1', nil, text_type_headers
      error = {"errors" => [
                            {"message" => "Only requests with Content-Type: application/json or application/vnd.api+json are allowed"}
                           ]}
      expect(JSON.parse(response.body)).to eq(error)
    end

    it 'should allow get requests with any format' do
      get '/api/me', nil, text_type_headers
      expect(response.status).to eq(401)
    end
  end
end
