require 'spec_helper'

describe Api::V1::ProjectsController, type: :controller do
  let!(:user) {
    create(:user)
  }

  let!(:projects) {
    create_list(:project_with_contents, 2, owner: user)
  }

  let(:api_resource_name) { "projects" }
  let(:api_resource_attributes) do 
    [ "id", "name", "display_name", "classifications_count", "subjects_count", "updated_at", "created_at", "available_languages"]
  end
  let(:api_resource_links) do
    [ "projects.owner", "projects.workflows", "projects.subject_sets", "projects.project_contents" ]
  end

  before(:each) do
    default_request(scopes: ["public", "project"], user_id: user.id)
  end

  describe "#index" do
    before(:each) do
      get :index
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should have 2 items by default" do
      expect(json_response[api_resource_name].length).to eq(2)
    end

    it_behaves_like "an api response"
  end

  describe "#show" do
    before(:each) do
      get :show, id: projects.first.id
    end

    it "should return 200" do
      expect(response.status).to eq(200)
    end

    it "should return the resquested project" do
      expect(json_response[api_resource_name].length).to eq(1)
    end

    it_behaves_like "an api response"
  end

end
