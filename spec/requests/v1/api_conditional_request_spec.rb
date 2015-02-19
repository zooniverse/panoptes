require 'spec_helper'

describe "api should allow conditional requests", type: :request do
  include APIRequestHelpers
  let(:user) { create(:user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: "public project") }
  let!(:project) { create(:project_with_contents, owner: user) }
  let(:url) { "/api/projects/#{project.id}" }
  let!(:etag) do
    get url, nil,
        { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
          "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
    response.headers['ETag']
  end
  
  shared_examples "precondition required" do
    let(:ok_status) { method == :put ? :ok : :no_content }
    
    it "should require if-unmodified-since header" do
      send method, url, body.to_json,
           { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "CONTENT_TYPE" => "application/json",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
      expect(response).to have_http_status(:precondition_required)
    end

    it "should fail request if precondition not met" do
      project.name = "gazorpazorp"
      project.save!
      send method, url, body.to_json,
           { "If-Match" => etag,
             "CONTENT_TYPE" => "application/json",
             "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
      expect(response).to have_http_status(:precondition_failed)
    end

    it "should succeed if precondition is met" do 
      send method, url, body.to_json,
           { "If-Match" => etag,
             "CONTENT_TYPE" => "application/json",
             "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
      expect(response).to have_http_status(ok_status)
    end
  end

  shared_examples "returns etag" do
    before(:each) do
      send method, url, nil, 
          { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
            "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
    end
    
    it "should return the ETag Header" do
      expect(response.headers['ETag']).to_not be_nil 
    end
  end

  shared_examples "304s when not modified" do
    before(:each) do
      send method, url, nil, 
          { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
            "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}",
            "If-None-Match" => etag }
    end

    it 'should return not modified' do
      expect(response).to have_http_status(:not_modified)
    end
  end
  
  context "PUT requests"  do
    let(:method) { :put }
    let(:body) do
      { "projects" => { "name" => "dave" } }
    end

    it_behaves_like "precondition required"
  end

  context "DELETE requests" do
    let(:body) { nil }
    let(:method) { :delete }

    it_behaves_like "precondition required"
  end

  context "HEAD requests" do
    let(:method) { :head }
    
    it_behaves_like "returns etag"
    it_behaves_like "304s when not modified"
  end
  
  context "GET requests" do
    let(:method) { :get }
    
    context "show actions" do
      it_behaves_like "returns etag"
      it_behaves_like "304s when not modified"
    end
    
    context "index actions" do
      let!(:project) { create_list(:project_with_contents, 2, owner: user).first }
      let(:url) { "/api/projects" }
      
      it_behaves_like "returns etag"
      it_behaves_like "304s when not modified"

      context 'when an item is deleted from the collection' do
        it 'should return 200 ' do
          project.destroy!
          get url, nil, 
              { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
                "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}",
                "If-None-Match" => etag }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
