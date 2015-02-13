require 'spec_helper'

def metadata_values
  {
    started_at: DateTime.now,
    finished_at: DateTime.now,
    workflow_version: "1.1",
    user_language: 'en',
    user_agent: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0"
  }
end

def annotation_values
  [ { "task" => "question_key",
       "value" => "question_answer" },
    { "task" => "age",
      "value" => "adult"} ]
end

def setup_create_request(project_id, workflow_id, subject_id)
  request.session = { cellect_hosts: { workflow_id.to_s => "example.com" } }
  params =
    {
      classifications: {
        completed: true,
        metadata: metadata_values,
        annotations: annotation_values,
        links: {
          project: project_id,
          workflow: workflow_id,
          subjects: [subject_id]
        }
      }
    }
  case
  when !gold_standard.nil?
    params[:classifications].merge!(gold_standard: gold_standard)
  when invalid_property
    params[:classifications].merge!(invalid_property => "a fake value")
  end

  post :create, params
end

def create_classification_with_subject
  setup_create_request(project.id, workflow.id, subject.id)
end

describe Api::V1::ClassificationsController, type: :controller do
  let!(:user) { create(:user) }
  let(:gold_standard) { nil }
  let(:invalid_property) { nil }
  let(:classification) { create(:classification, user: user) }
  let(:project) { create(:full_project) }
  let!(:workflow) { project.workflows.first }
  let!(:set_member_subject) { workflow.subject_sets.first.set_member_subjects.first }
  let!(:subject) { set_member_subject.subject }
  let(:created_classification_id) { created_instance_id("classifications") }

  let(:api_resource_name) { "classifications" }
  let(:api_resource_attributes) do
    [ "id", "annotations", "created_at" ]
  end
  let(:api_resource_links) do
    [ "classifications.project",
      "classifications.subjects",
      "classifications.user",
      "classifications.user_group" ]
  end

  let(:scopes) { %w(classification) }
  let(:authorized_user) { user }
  let(:resource_class) { Classification }

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: scopes
    end

    describe "#index" do
      let!(:classifications) { create_list(:classification, 2, user: user) }
      let!(:private_resource) { create(:classification) }
      let(:n_visible) { 2 }

      it_behaves_like "is indexable"
    end

    describe "#show" do
      let(:resource) { classification }
      it_behaves_like "is showable"
    end

    describe "#create" do
      context "with subject_ids" do
        let(:create_action) { create_classification_with_subject }

        it_behaves_like "a classification create"
        it_behaves_like "a classification lifecycle event"
        it_behaves_like "a gold standard classfication"

        context "when extra invalid classifcation properties are added" do
          let!(:invalid_property) { :custom_field }

          it "should fail via the schema validator with the correct message" do
            create_action
            error = json_response["errors"].first["message"]
            expected_error = {
              "schema" => "contains additional properties [\"custom_field\"] outside of the schema when none are allowed"
            }.to_s
            expect(error).to match(expected_error)
          end
        end

        context "when invalid link id strings are used" do

          it "should fail via the schema validator with the correct message" do
            req_params = [ project.id,
                           "MOCK_WORKFLOW_FOR_CLASSIFIER",
                           "MOCK_SUBJECT_FOR_CLASSIFIER" ]
            setup_create_request(*req_params)
            error = json_response["errors"].first["message"]
            expected_error = { "links/workflow"   => "value \"MOCK_WORKFLOW_FOR_CLASSIFIER\" did not match the regex '^[0-9]*$'",
                               "links/subjects/0" => "value \"MOCK_SUBJECT_FOR_CLASSIFIER\" did not match the regex '^[0-9]*$'"}.to_s
            expect(error).to match(expected_error)
          end
        end
      end
    end
  end

  describe "#update" do
    context "an incomplete classification" do
      let(:resource) { create(:classification, user: authorized_user, completed: false) }
      let(:test_attr) { :completed }
      let(:test_attr_value) { true }
      let(:update_params) do
        {
          classifications: {
            completed: true,
            annotations: [{ "task" => "q-1",
                            "value" => "round" }]
          }
        }
      end

      it_behaves_like "is updatable"

      it "should call the classification lifecycle from the yield block" do
        expect(controller).to receive(:lifecycle).with(:update, resource)
        default_request scopes: scopes, user_id: authorized_user.id
        params = update_params.merge(id: resource.id)
        put :update, params
      end
    end

    context "a complete classification" do
      it 'should return 403' do
        default_request scopes: scopes, user_id: authorized_user.id
        classification = create(:classification, user: authorized_user, completed: true)
        put :update, id: classification.id
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "#destroy" do
    context "an incomplete classification" do
      let(:resource) do
        create(:classification, user: authorized_user, completed: false)
      end

      it_behaves_like "is destructable"
    end

    context "a complete classification" do
      it 'should return 403' do
        default_request scopes: scopes, user_id: authorized_user.id
        classification = create(:classification,
                                user: authorized_user,
                                completed: true)
        delete :destroy, id: classification.id
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "a non-logged in user" do
    before(:each) do
      stub_content_filter
    end

    describe "#create" do

      it "should not set the user" do
        create_classification_with_subject
        user = Classification.find(created_classification_id).user
        expect(user).to be_blank
      end

      context "with subject_ids" do
        let(:create_action) { create_classification_with_subject }

        it_behaves_like "a classification create"
      end
    end
  end
end
