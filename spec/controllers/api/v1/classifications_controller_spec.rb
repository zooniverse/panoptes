require 'spec_helper'

def metadata_values
  {
    started_at: DateTime.now,
    finished_at: DateTime.now,
    workflow_version: "1.1",
    user_language: 'en',
    user_agent: "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:30.0) Gecko/20100101 Firefox/30.0",
    utc_offset: Time.now.utc_offset
  }
end

def annotation_values
  [ { "task" => "question_key",
       "value" => "question_answer" },
    { "task" => "age",
      "value" => "adult"} ]
end

def setup_create_request(project_id: project.id,
                         workflow_id: workflow.id,
                         subject_id: subject.id,
                         metadata: metadata_values)
  params =
    {
      classifications: {
        completed: true,
        metadata: metadata,
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

def create_gold_standard
  create(:gold_standard_classification, project: project, user: project.owner, workflow: workflow)
end

describe Api::V1::ClassificationsController, type: :controller do
  let(:user) { create(:user) }
  let(:gold_standard) { nil }
  let(:invalid_property) { nil }
  let(:classification) { create(:classification, user: user) }
  let(:project) { create(:full_project) }
  let(:workflow) { project.workflows.first }
  let(:set_member_subject) { workflow.subject_sets.first.set_member_subjects.first }
  let(:subject) { set_member_subject.subject }
  let(:created_classification_id) { created_instance_id("classifications") }

  let(:api_resource_name) { "classifications" }
  let(:api_resource_attributes) do
    [ "id", "annotations", "created_at", "metadata" ]
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

  describe "#index" do
    before(:each) do
      default_request user_id: authorized_user.id, scopes: scopes
    end

    describe "#page_size" do
      let(:response_page_size) do
        json_response["meta"]["classifications"]["page_size"]
      end

      it "should return the requested amount" do
        get :index, page_size: 50
        expect(response_page_size).to eq(50)
      end

      it "should return the max limit" do
        limit = Panoptes.max_page_size_limit
        get :index, page_size: limit + 1
        expect(response_page_size).to eq(limit)
      end
    end
  end

  describe "#incomplete" do
    let!(:complete) { create(:classification, user: user) }
    let!(:incomplete) { create(:classification, user: user, completed: false) }
    let(:n_visible) { 1 }

    before(:each) do
      default_request user_id: authorized_user.id, scopes: scopes
      get :incomplete
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it "should only return the incomplete one", :aggregate_failures do
      resources = json_response[api_resource_name]
      expect(resources.length).to eq 1
      c = Classification.find(resources.first["id"])
      expect(c.incomplete?).to eq(true)
    end
  end

  describe "#project" do
    let(:project) { create(:full_project) }
    let!(:classifications) { create_list(:classification, 2, project: project) }
    let!(:other_classification) { create(:classification) }
    let(:authorized_user) { project.owner }

    before(:each) do
      default_request user_id: authorized_user.id, scopes: scopes
    end

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should return only the project ones' do
      get :project
      projects = json_response['classifications']
        .map { |c| c["links"]["project"] }.uniq
      expect(projects).to match_array([project.id.to_s])
    end

    it 'should be filterable by subject_id' do
      get :project, subject_id: classifications.first.subject_ids.first
      expect(json_response['classifications'].first['id'].to_i)
        .to eq(classifications.first.id)
    end

    it 'should be filterable by a list of subject ids' do
      ids = classifications.map{|c| c.subject_ids.first}.join(',')
      get :project, subject_id: ids
      expect(json_response['classifications'].map{|c| c['id'].to_i})
        .to match_array(classifications.map(&:id))
    end
  end

  describe "#gold_standard" do
    let(:gs) { create_gold_standard }
    let!(:classifications) { [ classification, gs ] }
    let(:another_gs_in_workflow) { create_gold_standard }
    let(:another_gs) { create(:gold_standard_classification, project: project, user: project.owner) }
    let(:public_gold_standard) { true }
    let(:workflow) { create(:workflow, public_gold_standard: public_gold_standard) }
    let(:filtered_ids) do
      json_response['classifications'].map{|c| c['id'].to_i}
    end

    context "with an admin user" do
      let(:authorized_user) { create(:user, admin: true) }
      let(:gold_standard_ids) do
        [gs.id, another_gs.id, another_gs_in_workflow.id].map(&:to_s)
      end

      before(:each) do
        another_gs
        another_gs_in_workflow
        default_request scopes: scopes, user_id: authorized_user.id
        get :gold_standard, admin: true
      end

      it 'should only return gold standard classifications', :aggregate_failures do
        ids = created_instance_ids("classifications")
        expect(ids).to match_array(gold_standard_ids)
      end
    end

    context "with a logged in user" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'should only return the gold standard classification', :aggregate_failures do
        get :gold_standard
        expect(json_response['classifications'].length).to eq(1)
        c_id = json_response['classifications'].first['id']
        expect(c_id).to eq(gs.id.to_s)
      end

      it 'should be filterable by a workflow id' do
        another_gs
        get :gold_standard, workflow_id: gs.workflow_id
        expect(filtered_ids).to match_array([gs.id])
      end

      describe "subject_ids" do
        before(:each) { another_gs_in_workflow }

        it 'should be filterable by a subject id' do
          get :gold_standard, subject_id: gs.subject_ids.first
          expect(filtered_ids).to match_array([gs.id])
        end

        it 'should be filterable by a list of subject ids' do
          get :gold_standard, subject_ids: gs.subject_ids.join(',')
          expect(filtered_ids).to match_array([gs.id])
        end
      end
    end

    context "when a user is not logged in" do

      it "should return all the gold standard data for the supplied workflow" do
        another_gs_in_workflow
        get :gold_standard, workflow_id: workflow.id
        expect(json_response[api_resource_name].length).to eq(2)
      end

      context "when the workflow does not have public gold_standard flag" do
        let(:public_gold_standard) { false }

        it "should return an empty resource set" do
          get :gold_standard, workflow_id: workflow.id
          expect(json_response[api_resource_name].length).to eq(0)
        end
      end
    end
  end

  describe "#show" do
    before(:each) do
      default_request user_id: user.id, scopes: scopes
    end

    let(:resource) { create(:classification, user: user) }
    it_behaves_like "is showable"
  end

  describe "#create" do

    context "with subject_ids" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
      end

      let(:create_action) { setup_create_request }

      it_behaves_like "a classification create"
      it_behaves_like "a classification lifecycle event"
      it_behaves_like "a gold standard classfication"

      context "when extra invalid classification properties are added" do
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
          req_params = { project_id: project.id,
                         workflow_id: "MOCK_WORKFLOW_FOR_CLASSIFIER",
                         subject_id: "MOCK_SUBJECT_FOR_CLASSIFIER" }
          setup_create_request(req_params)
          error = json_response["errors"].first["message"]
          expected_error = { "links/workflow"   => "value \"MOCK_WORKFLOW_FOR_CLASSIFIER\" did not match the regex '^[0-9]*$'",
                             "links/subjects/0" => "value \"MOCK_SUBJECT_FOR_CLASSIFIER\" did not match the regex '^[0-9]*$'"}.to_s
          expect(error).to match(expected_error)
        end
      end

      context "when a subject has been classified before" do
        let(:create_action) { setup_create_request(metadata: metadata_values.merge(seen_before: true)) }
        it_behaves_like "a classification create"

        it "should not count towards retirement" do
          expect(ClassificationCountWorker).to_not receive(:perform_async)
          create_action
        end
      end
    end

    context "a non-logged in user" do
      before(:each) do
        stub_content_filter
      end

      it "should not set the user" do
        setup_create_request
        user = Classification.find(created_classification_id).user
        expect(user).to be_blank
      end

      context "with subject_ids" do
        let(:create_action) { setup_create_request }
        let(:user) { nil }

        it_behaves_like "a classification create"
      end
    end

    context "when redis is unavailable" do
      it 'should not raise an error but still report it' do
        stub_content_filter
        allow_any_instance_of(ClassificationLifecycle)
          .to receive(:queue)
          .and_raise(Redis::CannotConnectError)
        expect(Honeybadger).to receive(:notify)
        expect do
          setup_create_request
        end.not_to raise_error
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
end
