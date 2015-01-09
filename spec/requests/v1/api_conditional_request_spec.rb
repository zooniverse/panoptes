require 'spec_helper'

describe "api should allow conditional requests", type: :request do
  include APIRequestHelpers
  let(:user) { create(:user) }
  let!(:project) { create(:project_with_contents, owner: user) }
  let(:url) { "/api/projects/#{project.id}" }
  
  before(:each) do
    allow_any_instance_of(Api::ApiController)
      .to receive(:doorkeeper_token)
           .and_return(token(["public", "project"], user.id))
  end

  shared_examples "precondition required" do
    let(:ok_status) { method == :put ? :ok : :no_content }
    
    it "should require if-unmodified-since header" do
      send method, url, body.to_json,
           { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
             "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:precondition_required)
    end

    it "should fail request if precondition not met" do
      last_modified = project.updated_at
      project.name = "gazorpazorp"
      project.save!
      send method, url, body.to_json,
           { "If-Unmodified-Since" => last_modified,
             "CONTENT_TYPE" => "application/json",
             "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
      expect(response).to have_http_status(:precondition_failed)
    end

    it "should succeed if precondition is met" do 
      last_modified = project.updated_at
      send method, url, body.to_json,
           { "If-Unmodified-Since" => last_modified,
             "CONTENT_TYPE" => "application/json",
             "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
      expect(response).to have_http_status(ok_status)
    end
  end

  shared_examples "returns last modified" do
    before(:each) do
      get url, nil, 
          { "HTTP_ACCEPT" => "application/vnd.api+json; version=1" }
    end
    
    it "should return the Last-Modified Header" do
      expect(response.headers['Last-Modified']).to eq(project.updated_at.httpdate)
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
    end
    
    context "index actions" do
      let(:url) { "/api/projects" }
      
      it_behaves_like "returns last modified"
    end
  end

  
end
