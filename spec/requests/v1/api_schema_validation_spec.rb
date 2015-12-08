require 'spec_helper'

RSpec.describe "api should only accept certain content types", type: :request do
  include APIRequestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, owner: user) }
  let(:headers) do
    { "HTTP_ACCEPT" => "application/vnd.api+json; version=1",
      "CONTENT_TYPE" => "application/json" }
  end

  before(:each) do
    allow_any_instance_of(Api::ApiController).to receive(:doorkeeper_token).and_return(token(["public", "project"], user.id))
  end

  context "valid create params" do
    before(:each) do
      post "/api/subject_sets",
           { subject_sets: { display_name: "a name", links: { project: project.id.to_s } } }.to_json,
           headers
    end

    it 'should return 200' do
      expect(response.status).to eq(201)
    end
  end

  context "invalid create params" do
    before(:each) do
      post "/api/subject_sets",
           { subject_sets: { extra: "bad param", display_name: "a name", links: { project: project.id.to_s } } }.to_json,
           headers
    end

    it 'should return 422' do
      expect(response.status).to eq(422)
    end

    it 'should include an error message' do
      expect(JSON.parse(response.body)['errors'][0]).to_not be_empty
    end
  end
end
