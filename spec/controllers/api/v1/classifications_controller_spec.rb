require 'spec_helper'

def annotation_values
  [ { key: "age", value: "adult" },
    { started_at: DateTime.now },
    { finished_at: DateTime.now },
    { user_agent: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0" } ]
end

def setup_create_request(project_id, workflow_id, set_member_subject)
  request.session = { cellect_hosts: { workflow_id.to_s => "example.com" } }
  params = { classifications: { project_id: project_id,
                                workflow_id: workflow_id,
                                completed: true,
                                set_member_subject_id: set_member_subject.id,
                                subject_id: set_member_subject.subject_id,
                                annotations: annotation_values } }
  post :create, params
end

def create_classification
  setup_create_request(project.id, workflow.id, set_member_subject)
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
  let!(:user) { create(:user) }
  let(:classification) { create(:classification, user: user) }
  let(:project) { create(:full_project) }
  let!(:workflow) { project.workflows.first }
  let!(:set_member_subject) { workflow.subject_sets.first.set_member_subjects.first }
  let(:created_classification_id) { created_instance_id("classifications") }

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
      it "should create the user project preferences" do
        create_classification
        expect(UserProjectPreference.where(user: user, project: project).first).to_not be_nil
      end

      it "should set the communication preferences to the user's default" do
        create_classification
        expect(UserProjectPreference.where(user: user, project: project).first.email_communication).to eq(user.project_email_communication)
      end

      it 'should not create the user project preferences if they already exist' do
        create(:user_project_preference, user: user, project: project)
        create_classification
        expect(UserProjectPreference.where(user: user, project: project).length).to eq(1)
      end

      it "should setup the add seen command to cellect" do
        expect(stubbed_cellect_connection).to receive(:add_seen).with(
          subject_id: set_member_subject.subject_id.to_s,
          workflow_id: workflow.id.to_s,
          user_id: user.id,
          host: 'example.com'
        )
        create_classification
      end

      it "should set the user" do
        create_classification
        id = created_instance_id("classifications")
        expect(Classification.find(created_classification_id).user.id).to eq(user.id)
      end

      it_behaves_like "a classification create"

      describe "track user seen subjects" do
        let(:expected_params) do
          { subject_id: set_member_subject.subject_id.to_s,
            workflow_id: workflow.id.to_s,
            user_id: user.id }
        end

        it "should add the seen subject for the user" do
          expect(UserSeenSubject).to receive(:add_seen_subject_for_user).with(**expected_params)
          create_classification
        end

        it "should create a user seen subject" do
          expect do
            create_classification
          end.to change{UserSeenSubject.count}.from(0).to(1)
        end

        it "should add the subject ids to the user's seen subjects list" do
          create_classification
          set_member_subject.subject_id
        end

        context "with and invalid subject_id" do

          it "should gracefully return a json error" do
            allow(set_member_subject).to receive(:subject_id).and_return("not a valid id")
            create_classification
            expect(response.body).to eq(json_error_message("Subject ID is invalid, possibly not persisted."))
          end
        end
      end
    end
  end

  context "a non-logged in user" do
    before(:each) do
      stub_content_filter
    end

    describe "#create" do

      it "should not set the user" do
        create_classification
        expect(Classification.find(created_classification_id).user).to be_blank
      end

      it_behaves_like "a classification create"
    end
  end
end
