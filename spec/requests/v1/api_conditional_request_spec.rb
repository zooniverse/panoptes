require 'spec_helper'

describe "api should allow conditional requests", type: :request do
  include APIRequestHelpers
  let(:user) { create(:user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: "public project") }
  let!(:project) { create(:project_with_contents, owner: user) }
  let(:url) { "/api/projects/#{project.id}" }
  let!(:last_modified) { project.updated_at.httpdate }
  
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
      sleep 1
      project.name = "gazorpazorp"
      project.save!
      send method, url, body.to_json,
           { "If-Unmodified-Since" => last_modified,
             "CONTENT_TYPE" => "application/json",
             "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
      expect(response).to have_http_status(:precondition_failed)
    end

    it "should succeed if precondition is met" do 
      send method, url, body.to_json,
           { "If-Unmodified-Since" => last_modified,
             "CONTENT_TYPE" => "application/json",
             "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
      expect(response).to have_http_status(ok_status)
    end
  end

  shared_examples "returns last modified" do
    before(:each) do
      get url, nil, 
          { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}" }
    end
    
    it "should return the Last-Modified Header" do
      expect(response.headers['Last-Modified']).to eq(project.updated_at.httpdate)
    end
  end

  shared_examples "304s when not modified" do
    before(:each) do
      get url, nil, 
          { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}",
             "If-Modified-Since" => last_modified }
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

  context "GET requests" do
    context "show actions" do
      it_behaves_like "returns last modified"
      it_behaves_like "304s when not modified"
    end
    
    context "index actions" do
      let(:url) { "/api/projects" }
      
      it_behaves_like "returns last modified"
      it_behaves_like "304s when not modified"
    end
  end

  
end
