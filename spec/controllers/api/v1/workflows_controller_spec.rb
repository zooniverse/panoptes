require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let(:user) { create(:user) }
  let(:workflows) { create_list :workflow_with_contents, 2 }
  let(:workflow){ workflows.first }
  let(:project){ workflow.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'workflows' }
  let(:resource_class) { Workflow }
  let(:authorized_user) { owner }
  let(:default_params) { {format: :json} }

  let(:api_resource_attributes) do
    %w(id display_name tasks classifications_count subjects_count
    created_at updated_at first_task primary_language content_language
    version grouped prioritized pairwise retirement aggregation
    active mobile_friendly configuration finished_at public_gold_standard)
  end
  let(:api_resource_links)do
    %w(workflows.project workflows.subject_sets workflows.tutorial_subject
    workflows.attached_images)
  end
  let(:scopes) { %w(public project) }

  before(:each) do
    PaperTrail.enabled = true
    PaperTrail.enabled_for_controller = true
  end

  after(:each) do
    PaperTrail.enabled = false
    PaperTrail.enabled_for_controller = false
  end

  describe '#index' do
    let(:filterable_resources) { create_list(:workflow_with_subjects, 2) }
    let(:expected_filtered_ids) { [ filterable_resources.first.id.to_s ] }
    let(:private_project) { create(:private_project) }
    let(:private_resource) { create(:workflow, project: private_project) }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable' do
      before do
        private_resource
      end
    end

    it_behaves_like 'has many filterable', :subject_sets

    it_behaves_like "an indexable unauthenticated http cacheable response" do
      let(:action) { :index }
      let(:private_resource) do
        create(:workflow, project: private_project)
      end
    end

    it_behaves_like "an indexable authenticated http cacheable response" do
      let(:action) { :index }
      let(:private_resource) do
        create(:workflow, project: private_project)
      end
      let(:authorized_user) { private_project.owner }
    end

    describe "filter by" do
      before(:each) do
        filterable_resources
        default_request user_id: user.id, scopes: scopes
        get :index, filter_opts
      end

      context "filter by activated" do
        let!(:inactive_workflow) { create(:workflow, active: false) }
        let(:filter_opts) { {active: true} }

        it 'should only return activated workflows', :aggregate_failures do
          expect(json_response[api_resource_name].length).to eq(2)
          expect(json_response[api_resource_name].map{ |w| w['active'] }).to all( be true )
        end

        it 'should not include in active workflows' do
          expect(json_response[api_resource_name].map{ |w| w['id'] }).to_not include(inactive_workflow.id)
        end
      end
    end

    describe 'limiting fields' do
      before(:each) do
        filterable_resources
        default_request user_id: user.id, scopes: scopes
      end

      it 'should return only serialize the specified fields' do
        get :index, fields: 'display_name,subjects_count,does_not_exist'
        response_keys = json_response['workflows'].map(&:keys).uniq.flatten
        expect(response_keys).to match_array ['id', 'links', 'display_name', 'subjects_count']
      end
    end

    describe 'requesting published versions' do
      it 'should return the published version of records' do
        filterable_resources[0].publish!
        filterable_resources[0].update! tasks: {}, strings: {}
        get :index, published: true
        expect(json_response[api_resource_name].first["tasks"]).to be_present
      end
    end
  end

  describe '#update' do
    let(:subject_set) { create(:subject_set, project: project) }
    let(:tutorial) { create :tutorial, project: project }
    let(:resource) { create(:workflow_with_contents, active: false, project: project) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:test_relation) { :subject_sets }
    let(:test_relation_ids) { subject_set.id.to_s }
    let(:resource_id) { :workflow_id }
    let(:update_params) do
      {
        workflows: {
          display_name: "A Better Name",
          active: false,
          retirement: {criteria: "classification_count"},
          aggregation: {},
          configuration: {},
          public_gold_standard: true,
          tasks: {
            interest: {
             type: "draw",
             question: "Draw a Circle",
             next: "shape",
             tools: [
               {value: "red", label: "Red", type: 'point', color: 'red'},
               {value: "green", label: "Green", type: 'point', color: 'lime'},
               {value: "blue", label: "Blue", type: 'point', color: 'blue'}
             ]
           }
           },
           display_order_position: 1,
           links: {
            subject_sets: [subject_set.id.to_s],
            tutorials: [tutorial.id.to_s]
          }

        }
      }
    end

    it_behaves_like "is updatable"
    it_behaves_like "has updatable links"

    it_behaves_like "it syncs the resource translation strings" do
      let(:translated_klass_name) { resource.class.name }
      let(:translated_resource_id) { resource.id }
      let(:translated_language) { resource.primary_language }
      let(:controller_action) { :update }
      let(:translatable_action_params) { update_params.merge(id: resource.id) }
      let(:non_translatable_action_params) { {id: resource.id, workflows: {active: false}} }
    end

    context "workflow versions" do
      before do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'creates versions' do
        update_params[:id] = resource.id
        expect { put :update, update_params }.to change { resource.workflow_versions.count }.by(1)
      end
    end

    context "extracts strings from workflow" do
      let(:new_question) { "Contemplate" }
      before do
        default_request scopes: scopes, user_id: authorized_user.id
        update_params[:workflows][:tasks][:interest][:question] = new_question
        update_params[:id] = resource.id
      end

      it 'should replace "Draw a circle" with Contemplate', :aggregate_failures do
        put :update, update_params
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
        contents = instance.primary_content
        expect(instance.strings["interest.question"]).to eq(new_question)
        expect(contents.strings["interest.question"]).to eq(new_question)
      end

      context "when only updating the task content strings" do
        let(:new_question) { "Can you mark the penguins." }
        let(:task_only_update_params) do
          {
            workflows: { tasks: update_params[:workflows][:tasks] },
            id: resource.id
          }
        end

        it "should touch the workflow resource" do
          expect {
            put :update, task_only_update_params
          }.to change {
            resource.reload.updated_at
          }
        end

        it 'should update the associated contents' do
          put :update, task_only_update_params
          instance = Workflow.find(created_instance_id(api_resource_name))
          contents = instance.primary_content
          expect(instance.strings["interest.question"]).to eq(new_question)
          expect(contents.strings["interest.question"]).to eq(new_question)
        end
      end

      context "when updating without tasks" do
        let(:no_task_update_params) do
          {
            workflows: { active: true },
            id: resource.id
          }
        end

        it "should update the workflow active state" do
          expect {
            put :update, no_task_update_params
          }.to change {
            resource.reload.active
          }.to(true)
        end

        it "should not update the workflow tasks" do
          expect {
            put :update, no_task_update_params
          }.not_to change {
            resource.reload.tasks
          }
        end

        it "should not update the workflow content strings" do
          expect {
            put :update, no_task_update_params
          }.not_to change {
            resource.primary_content.reload.strings
          }
        end
      end
    end

    context "when a project is live" do
      before(:each) do
        resource.update!(active: true)
        project = resource.project
        project.live = true
        project.save!

        default_request user_id: authorized_user.id, scopes: scopes
        put :update, id: resource.id, workflows: update_params
      end

      context "when the update requests tasks to change" do
        let(:update_params) do
          {
            tasks: {
              wintrest: {
                type: "draw",
                question: "Draw a Circle",
                next: "shape",
                tools: [
                  {value: "red", label: "Red", type: 'point', color: 'red'},
                  {value: "green", label: "Green", type: 'point', color: 'lime'}
                ]
              }
            }
          }
        end

        it 'should return 403' do
          expect(response).to have_http_status(:forbidden)
        end

        it 'should not have changed the content model' do
          content = resource.primary_content
          expect{ content.reload }.to_not change{content.strings}
        end
      end

      context "when the update requests grouped to change" do
        let(:update_params) { { grouped: !resource.grouped } }

        it 'should return 403' do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the update requests pairwise to change" do
        let(:update_params) { { pairwise: !resource.pairwise } }

        it 'should return 403' do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the update requests prioritizied to change" do
        let(:update_params) { { prioritized: !resource.prioritized } }

        it 'should return 403' do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the update requests first_task to change" do
        let(:update_params) { { first_task: "last_task" } }

        it 'should return 403' do
          expect(response).to have_http_status(:forbidden)
        end
      end

      context "when the user updates help text within a task" do
        let(:update_params) do
          tasks = resource.tasks
          tasks["interest"]["help"] = "Something new"
          {tasks: tasks}
        end

        it 'should return 200' do
          expect(response).to have_http_status(:ok)
        end

        it 'should update the content model' do
          content = resource.primary_content
          expect{ content.reload }.to change{ content.strings }
        end
      end
    end

    context "workflow_contents task strings" do
      let(:tasks) { update_params.dig(:workflows, :tasks) }
      let(:params) do
        { workflows: { tasks: tasks }, id: resource.id }
      end

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it "should update the primary content task strings" do
        put :update, params
        response_tasks = json_response['workflows'][0]['tasks']
        expect(response_tasks).to eq(tasks.deep_stringify_keys)
      end

      it "should touch the workflow resource to modify the cache_key / etag" do
        expect {
          put :update, params
        }.to change { resource.reload.updated_at }
      end
    end
  end

  describe "#update_links" do
    RSpec.shared_examples "reloads the non logged in queues" do |link_to_test|
      let(:update_link_params) do
        {
          link_relation: test_relation.to_s,
          test_relation => test_relation_ids,
          resource_id => resource.id
        }
      end

      context "with authorized user" do
        after do
          default_request scopes: scopes, user_id: authorized_user.id
          post :update_links, update_link_params
        end

        it 'should run refresh workflow status worker' do
          expect(RefreshWorkflowStatusWorker)
            .to receive(:perform_async)
        end

        case link_to_test
        when :subject_sets
          it "should call post link subject set workers", :aggregate_failures do
            test_relation_ids.each do |set_id|
              expect(SubjectSetStatusesCreateWorker)
              .to receive(:perform_async)
              .with(set_id, resource.id)
            end
            expect(NotifySubjectSelectorOfChangeWorker)
              .to receive(:perform_async)
              .with(resource.id)
          end
        when :retired_subjects
          it 'should notify the subject selector that subjects were retired' do
            expect(NotifySubjectSelectorOfRetirementWorker).to receive(:perform_async)
              .with(linked_resource.id.to_s, workflow.id)
          end
        end
      end
    end

    context 'linking a subject set' do
      let(:subject_set_project) { project }
      let(:linked_resource) { create(:subject_set_with_subjects, project: subject_set_project) }
      let(:subject_set_id) { linked_resource.id.to_s }
      let(:test_attr) { :display_name }
      let(:test_relation) { :subject_sets }
      let(:test_relation_ids) { [ linked_resource.id.to_s ] }
      let(:expected_copies_count) { linked_resource.subjects.count }
      let(:resource) { workflow }
      let(:resource_id) { :workflow_id }
      let(:copied_resource) { resource.reload.send(test_relation).first }

      it_behaves_like "supports update_links"
      it_behaves_like "reloads the non logged in queues", :subject_sets

      it "should call SubjectSetStatusesCreateWorker" do
        expect(SubjectSetStatusesCreateWorker)
        .to receive(:perform_async)
        .with(subject_set_id, resource.id)

        default_request scopes: scopes, user_id: authorized_user.id
        params = {
          link_relation: test_relation.to_s,
          test_relation => test_relation_ids,
          resource_id => resource.id
        }
        post :update_links, params
      end

      it "should handle non-array link formats" do
        default_request scopes: scopes, user_id: authorized_user.id
        params = {
          link_relation: test_relation.to_s,
          test_relation => linked_resource.id.to_s,
          resource_id => resource.id
        }
        post :update_links, params
        linked_subject_set_ids = resource.subject_sets.pluck(:id)
        expect(linked_subject_set_ids).to eq([linked_resource.id])
      end

      context "when the subject_set links belong to another project" do
        let!(:subject_set_project) do
          workflows.find { |w| w.project != project }.project
        end

        it_behaves_like "supports update_links via a copy of the original" do

          it 'should have the same name' do
            update_via_links
            expect(copied_resource.display_name).to eq(linked_resource.display_name)
          end

          it 'should belong to the correct project' do
            update_via_links
            expect(copied_resource.project_id).to eq(resource.project_id)
          end

          it 'should create copies of every subject via set_member_subjects' do
            expect{ update_via_links }.to change { SetMemberSubject.count }.by(expected_copies_count)
          end
        end
      end
    end

    context 'linking a tutorial' do

      let(:tutorial_project) { project }
      let(:linked_resource) { create(:tutorial, project: tutorial_project) }
      let(:resource) { workflow }
      let(:resource_id) { :workflow_id }
      let(:test_relation) { :tutorials }
      let(:test_relation_ids) { [ linked_resource.id.to_s ] }

      it_behaves_like "supports update_links" do
        it 'links the tutorial to the workflow' do
          expect(resource.tutorials.pluck(:id).map(&:to_s)).to eq(test_relation_ids)
        end

      end
    end

    context 'retiring subjects via links' do
      let(:subject_set_project) { project }
      let(:subject_set) { create(:subject_set, project: project, workflows: [project.workflows.first]) }
      let(:subject_set_id) { subject_set.id }
      let(:linked_resource) { create(:subject, subject_sets: [subject_set]) }
      let(:test_attr) { :display_name }
      let(:test_relation) { :retired_subjects }
      let(:test_relation_ids) { [ linked_resource.id.to_s ] }
      let(:resource) { workflow }
      let(:resource_id) { :workflow_id }

      before do
        resource.update_column :display_order, nil
      end

      it_behaves_like "supports update_links" do
        it 'marks the subject as retired' do
          expect(linked_resource.retired_for_workflow?(resource)).to be_truthy
        end
      end

      it_behaves_like "reloads the non logged in queues", :retired_subjects
    end
  end

  describe '#create' do
    let(:test_attr) { :display_name }
    let(:test_attr_value) { 'Test workflow' }
    let(:create_task_params) do
      {
        interest: {
          type: "draw",
          question: "Draw a Circle",
          next: "shape",
          tools: [
            {value: "red", label: "Red", type: 'point', color: 'red'},
            {value: "green", label: "Green", type: 'point', color: 'lime'},
            {value: "blue", label: "Blue", type: 'point', color: 'blue'}
          ]
        },
        shape: {
          type: 'multiple',
          question: "What shape is this galaxy?",
          answers: [
            {value: 'smooth', label: "Smooth"},
            {value: 'features', label: "Features"},
            {value: 'other', label: 'Star or artifact'}
          ],
          next: nil
        }
      }
    end

    let(:create_params) do
      {
        workflows: {
          display_name: 'Test workflow',
          first_task: 'interest',
          active: true,
          retirement: {criteria: "classification_count"},
          aggregation: {public: true},
          configuration: {autoplay_subjects: true},
          public_gold_standard: true,
          tasks: create_task_params,
          grouped: true,
          prioritized: true,
          primary_language: 'en',
          display_order_position: 1,
          links: {project: project.id.to_s}
        }
      }
    end

    it_behaves_like "it syncs the resource translation strings", non_translatable_attributes_possible: false do
      let(:translated_klass_name) { Workflow.name }
      let(:translated_resource_id) { be_kind_of(Integer) }
      let(:translated_language) { create_params.dig(:workflows, :primary_language) }
      let(:controller_action) { :create }
      let(:translatable_action_params) { create_params }
    end

    context "when the linked project is owned by a user" do
      it_behaves_like "is creatable"
    end

    context "when a project is owned by a user group" do
      let(:membership) { create(:membership, state: 0, roles: ["project_editor"]) }
      let(:project) { create(:project, owner: membership.user_group) }
      let(:authorized_user) { membership.user }

      it_behaves_like "is creatable"
    end

    context "workflow versions" do
      before do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it 'creates versions' do
        post :create, create_params
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.workflow_versions.count).to eq(1)
      end
    end

    context "extracts strings from workflow" do
      it 'should replace "Draw a circle" with 0' do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
        expect(instance.strings["interest.question"]).to eq("Draw a Circle")
      end
    end

    context "includes a tutorial subject" do
      let(:tut_sub) { create(:subject, project: project).id.to_s }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        create_params[:workflows][:links][:tutorial_subject] = tut_sub
        post :create, create_params
      end

      it 'responds with tutorial subject link' do
        expect(json_response['workflows'][0]['links']['tutorial_subject']).to eq(tut_sub)
      end

      it 'responds with a tutorial subject link template' do
        expect(json_response['links']['workflows.tutorial_subject']['href']).to eq("/subjects/{workflows.tutorial_subject}")
      end
    end

    context "when the project is live" do
      before(:each) do
        allow_any_instance_of(Project).to receive(:live).and_return(true)
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end

      it 'sets the workflow active to false' do
        expect(Workflow.find(json_response["workflows"][0]["id"]).active).to be false
      end
    end

    context "with an empty task set" do
      let(:create_task_params) { {} }

      it_behaves_like "is creatable"
    end
  end

  describe '#destroy' do
    let(:resource) { workflow }

    it_behaves_like "is deactivatable" do
      let(:instances_to_disable) { [resource] }
    end
  end

  describe '#destroy_links' do
    context "removing a subject set from the workflow" do
      let!(:linked_resources) do
        [
          create(:subject_set_with_subjects, workflows: [workflow], project: project),
          create(:subject_set_with_subjects, workflows: [workflow], project: project)
        ]
      end
      let(:linked_resource_to_destroy) { linked_resources.sample }
      let(:remaining_linked_resource) do
        linked_resources - [linked_resource_to_destroy ]
      end
      let(:link_ids) { linked_resource_to_destroy.id.to_s }
      let(:destroy_link_params) do
        {
          link_relation: "subject_sets",
          link_ids: link_ids,
          workflow_id: workflow.id
        }
      end
      let(:still_linked_sets) { workflow.reload.subject_sets }

      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
      end

      it "should unlink the subject set from the workflow" do
        expect(workflow.subject_sets).to match_array(linked_resources)
        delete :destroy_links, destroy_link_params
        expect(still_linked_sets).to match_array(remaining_linked_resource)
      end

      it "should call the appropriate workers" do
        expect(NotifySubjectSelectorOfChangeWorker)
          .to receive(:perform_async)
          .with(workflow.id)
        expect(RefreshWorkflowStatusWorker)
          .to receive(:perform_async)
          .with(workflow.id)
        delete :destroy_links, destroy_link_params
      end

      context "with link_ids as a comma separated list" do
        let(:link_ids) { linked_resources.map(&:id).join(',') }

        it "should unlink the subject set from the workflow" do
          delete :destroy_links, destroy_link_params
          expect(still_linked_sets).to match_array([])
        end
      end

      context 'with a subject_set not linked to the workflow' do
        let(:other_subject_set) { create(:subject_set) }
        let(:link_ids) { other_subject_set.id.to_s }

        it "should not unlink" do
          delete :destroy_links, destroy_link_params
          expect(still_linked_sets).to match_array(linked_resources)
        end

        it "should respond with not_found" do
          delete :destroy_links, destroy_link_params
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "#show" do
    let(:resource) { workflows.first }

    it_behaves_like "is showable"

    describe "http caching" do
      let(:action) { :show }
      let(:private_resource) do
        project = create(:private_project, owner: authorized_user)
        create(:workflow, project: project)
      end
      let(:private_resource_id) { private_resource.id }
      let(:public_resource_id) { resource.id }

      it_behaves_like "a showable unauthenticated http cacheable response"
      it_behaves_like "a showable authenticated http cacheable response"
    end
  end

  describe '#retired_subjects' do
    before do
      default_request scopes: scopes, user_id: authorized_user.id
    end

    let(:subject_set_project) { project }
    let(:subject_set) { create(:subject_set, project: project, workflows: [project.workflows.first]) }
    let(:subject_set_id) { subject_set.id }
    let(:subject) { create(:subject, subject_sets: [subject_set]) }

    it 'returns a 204 status' do
      post :retire_subjects, workflow_id: workflow.id, subject_id: subject.id
      expect(response.status).to eq(204)
    end

    it 'queues a retire subject worker' do
      expect(RetireSubjectWorker).to receive(:perform_async).with(workflow.id, [subject.id], nil)
      post :retire_subjects, workflow_id: workflow.id, subject_id: subject.id
    end

    it 'throws an unpermitted params error when retired_reason is invalid', :aggregate_failures do
      post :retire_subjects, workflow_id: workflow.id, subject_id: subject.id, retirement_reason: "notreal"
      expect(json_response['errors'][0]['message'])
        .to eq("Retirement reason is not included in the list")
      expect(response.status).to eq(422)
    end
  end

  describe "versioning" do
    let(:resource) { workflow }
    let!(:existing_versions) { resource.versions.length }
    let(:num_times) { 11 }
    let(:update_proc) { Proc.new { |resource, n| resource.update!(prioritized: (n % 2 == 0)) } }
    let(:resource_param) { :workflow_id }

    it_behaves_like "a versioned resource"
  end

  describe "#create_classifications_export" do
    let(:test_attr) { :type }
    let(:api_resource_name) { "media" }
    let(:api_resource_attributes) do
      ["id", "src", "created_at", "content_type", "media_type", "href"]
    end
    let(:api_resource_links) { [] }
    let(:resource_class) { Medium }
    let(:content_type) { "text/csv" }
    let(:resource_url) { /http:\/\/test.host\/api\/workflows\/#{workflow.id}\/classifications_export/ }
    let(:test_attr_value) { "workflow_classifications_export" }
    let(:create_params) do
      {
        workflow_id: workflow.id,
        media: {
          content_type: content_type,
          metadata: { recipients: create_list(:user, 1).map(&:id) }
        }
      }
    end

    it_behaves_like "is creatable", :create_classifications_export

    it_behaves_like "it forbids data exports" do
      let(:project) { workflow.project }
    end
  end
end
