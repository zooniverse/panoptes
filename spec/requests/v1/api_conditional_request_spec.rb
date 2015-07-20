require 'spec_helper'

describe "api should allow conditional requests", type: :request do
  include APIRequestHelpers
  let(:user) { create(:user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id, scopes: "public project medium") }
  let!(:project) { create(:project_with_contents, owner: user) }
  let(:url) { "/api/projects/#{project.id}" }
  let(:api_default_params) do
    {
      "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
      "HTTP_AUTHORIZATION" => "Bearer #{access_token.token}"
    }
  end

  let(:etag) do
    get url, nil, api_default_params
    response.headers['ETag']
  end

  let(:modify) do
    project.name = "gazorpazorp"
    project.save!
  end

  let(:request_params) do
    { "If-Match" => etag, "CONTENT_TYPE" => "application/json" }.merge(api_default_params)
  end

  shared_examples "precondition required" do
    let(:ok_status) { method == :put ? :ok : :no_content }

    context "when the if-match header is not supplied" do
      before(:each) do
        send method, url, body.to_json, request_params.except("If-Match")
      end

      it "should require if-match header" do
        expect(response).to have_http_status(:precondition_required)
      end

      it "should have the required header message as response body" do
        error_message = "Request requires If-Match header to be present"
        expect(response.body).to eq(json_error_message(error_message))
      end
    end

    it "should fail request if precondition not met" do
      request_params
      modify
      send method, url, body.to_json, request_params
      expect(response).to have_http_status(:precondition_failed)
    end

    it "should succeed if precondition is met" do
      send method, url, body.to_json, request_params
      expect(response).to have_http_status(ok_status)
    end
  end

  shared_examples "returns etag" do
    before(:each) do
      send method, url, nil, api_default_params
    end

    it "should return the ETag Header" do
      expect(response.headers['ETag']).to_not be_nil
    end
  end

  shared_examples "304s when not modified" do
    before(:each) do
      send method, url, nil, api_default_params.merge("If-None-Match" => etag)
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

    context "for projects" do

      it_behaves_like "precondition required"
    end

    context "for media" do
      let(:modify) do
        media.content_type = "image/gif"
        media.save!
      end

      describe "has_many relations" do
        let!(:media) { create(:medium, linked: project, type: "project_attached_image") }
        let(:url) { "/api/projects/#{project.id}/attached_images/#{media.id}"}

        it_behaves_like "precondition required"
      end

      describe "has_one relations" do
        let!(:media) { create(:medium, linked: project, type: "project_avatar") }
        let(:url) { "/api/projects/#{project.id}/avatar"}

        it_behaves_like "precondition required"
      end
    end
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
        it 'should return 200' do
          request_params
          project.destroy!
          get url, nil, request_params.except("CONTENT_TYPE")
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
