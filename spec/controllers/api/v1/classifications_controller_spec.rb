require 'spec_helper'

def annotation_values
  [ { value: "adult" },
    { started_at: DateTime.now },
    { finished_at: DateTime.now },
    { user_agent: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0" } ]
end

def setup_create_request(project_id, workflow_id, subject_set_member)
  request.session = { cellect_hosts: { workflow_id.to_s => "example.com" } }
  params = { classification: { project_id: project_id,
                               workflow_id: workflow_id,
                               set_member_subject_id: subject_set_member.id,
                               subject_id: subject_set_member.subject_id,
                               annotations: annotation_values } }
  post :create, params
end

def create_classification
  setup_create_request(project.id, workflow.id, set_member_subject)
end

def created_classification_id
  json_response["classifications"][0]["id"]
end

shared_context "a classification create" do
  it "should return 201" do
    create_classification
    expect(response.status).to eq(201)
  end

  it "should set the Location header as per JSON-API specs" do
    create_classification
    id = created_classification_id
    expect(response.headers["Location"]).to eq("http://test.host/api/classifications/#{id}")
  end

  it "should create the classification" do
    expect do
      create_classification
    end.to change{Classification.count}.from(0).to(1)
  end
end

describe Api::V1::ClassificationsController, type: :controller do
  let(:classification) { create(:classification) }
  let(:project) { create(:full_project) }
  let!(:workflow) { project.workflows.first }
  let!(:set_member_subject) { workflow.subject_sets.first.set_member_subjects.first }
  let!(:user) { create(:user) }

  let(:api_resource_name) { "classifications" }
  let(:api_resource_attributes) do
    [ "id", "annotations", "created_at" ]
  end
  let(:api_resource_links) do
    [ "classifications.project",
      "classifications.set_member_subject",
      "classifications.user",
      "classifications.user_group" ]
  end

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: ["classifications"]
    end

    describe "#index" do

      before(:each) do
        classification
        get :index
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have one item by default" do
        expect(json_response[api_resource_name].length).to eq(1)
      end

      it_behaves_like "an api response"
    end

    describe "#show" do
      before(:each) do
        get :show, id: classification.id
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should have a single user" do
        expect(json_response[api_resource_name].length).to eq(1)
      end

      it_behaves_like "an api response"
    end

    describe "#create" do

      it "should setup the add seen command to cellect" do
        expect(stubbed_cellect_connection).to receive(:add_seen).with(
          subject_id: set_member_subject.id.to_s,
          workflow_id: workflow.id.to_s,
          user_id: user.id,
          host: 'example.com'
        )
        create_classification
      end

      it "should set the user" do
        create_classification
        expect(Classification.find(created_classification_id).user.id).to eq(user.id)
      end

      it_behaves_like "a classification create"
    end
  end

  context "a non-logged in user" do

    describe "#create" do

      it "should not set the user" do
        create_classification
        expect(Classification.find(created_classification_id).user).to be_blank
      end

      it_behaves_like "a classification create"
    end
  end
end
