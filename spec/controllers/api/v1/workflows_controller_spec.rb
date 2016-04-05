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
    version grouped prioritized pairwise retirement aggregation active
    configuration finished_at public_gold_standard)
  end
  let(:api_resource_links)do
    %w(workflows.project workflows.subject_sets workflows.tutorial_subject
    workflows.expert_subject_set workflows.attached_images)
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
    let!(:private_resource) { create(:workflow, project: private_project) }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable'
    it_behaves_like 'has many filterable', :subject_sets

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
  end

  describe '#update' do
    let(:subject_set) { create(:subject_set, project: project) }
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
                   retirement: { criteria: "classification_count" },
                   aggregation: { },
                   configuration: { },
                   public_gold_standard: true,
                   tasks: {
                           interest: {
                                      type: "draw",
                                      question: "Draw a Circle",
                                      next: "shape",
                                      tools: [
                                              {value: "red", label: "Red", type: 'point', color: 'red'},
                                              {value: "green", label: "Green", type: 'point', color: 'lime'},
                                              {value: "blue", label: "Blue", type: 'point', color: 'blue'},
                                             ]
                                     }
                          },
                   display_order_position: 1,
                   links: {
                           subject_sets: [subject_set.id.to_s],
                          }

                  }
      }
    end

    it_behaves_like "is updatable"
    it_behaves_like "has updatable links"

    context "extracts strings from workflow" do
      it 'should replace "Draw a circle" with 0' do
        default_request scopes: scopes, user_id: authorized_user.id
        put :update, update_params.merge(id: resource.id)
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
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
                                      {value: "green", label: "Green", type: 'point', color: 'lime'},
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
          tasks[:interest][:help] = "Something new"
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

        context "when the workflow has subjects" do
          it 'should call the reload queue worker' do
            expect(ReloadNonLoggedInQueueWorker).to receive(:perform_async).with(resource.id, subject_set_id)
          end

          it 'should not call the reload cellect worker when cellect is off' do
            expect(ReloadCellectWorker).not_to receive(:perform_async)
          end

          case link_to_test
          when :subject_sets
            context "when cellect is on" do
              before do
                allow(Panoptes).to receive(:cellect_on).and_return(true)
              end

              it 'should not call reload cellect worker' do
                expect(ReloadCellectWorker).not_to receive(:perform_async)
              end

              it 'should call reload cellect worker when workflow uses cellect' do
                allow_any_instance_of(Workflow)
                  .to receive(:using_cellect?).and_return(true)
                expect(ReloadCellectWorker).to receive(:perform_async)
                  .with(resource.id)
              end
            end
          when :retired_subjects
            it 'should not call reload cellect worker' do
              expect(ReloadCellectWorker).not_to receive(:perform_async)
            end

            it 'should not call the retire cellect worker' do
              expect(RetireCellectWorker).not_to receive(:perform_async)
            end

            context "when cellect is on" do
              before do
                allow(Panoptes).to receive(:cellect_on).and_return(true)
              end

              it 'should not call reload cellect worker' do
                expect(ReloadCellectWorker).not_to receive(:perform_async)
              end

              it 'should not call the retire cellect worker' do
                expect(RetireCellectWorker).not_to receive(:perform_async)
              end

              context "when the workflow is using cellect" do
                before do
                  allow_any_instance_of(Workflow)
                  .to receive(:using_cellect?).and_return(true)
                end

                it 'should not call reload cellect worker' do
                  expect(ReloadCellectWorker).not_to receive(:perform_async)
                end

                it 'should call retire cellect worker when workflow uses cellect' do
                  expect(RetireCellectWorker).to receive(:perform_async)
                    .with(linked_resource.id.to_s, workflow.id)
                end
              end
            end
          end
        end

        context "when the workflow has no subjects" do
          let(:linked_resource) { create(:subject_set, project: subject_set_project) }

          it "should not queue the worker" do
            expect(ReloadNonLoggedInQueueWorker).to_not receive(:perform_async)
            default_request scopes: scopes, user_id: authorized_user.id
            post :update_links, update_link_params
          end

          it 'should not attempt to call cellect', :aggregate_failures do
            expect(Panoptes).not_to receive(:use_cellect?)
            expect(ReloadCellectWorker).not_to receive(:perform_async)
          end
        end
      end

      context "without authorized user" do
        it 'should not call the reload queue worker' do
          expect(ReloadNonLoggedInQueueWorker).to_not receive(:perform_async)
          default_request scopes: scopes, user_id: create(:user).id
          post :update_links, update_link_params
        end

        it 'should not attempt to call cellect', :aggregate_failures do
          expect(Panoptes).not_to receive(:use_cellect?)
          expect(ReloadCellectWorker).not_to receive(:perform_async)
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
                           {value: "blue", label: "Blue", type: 'point', color: 'blue'},
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
                     retirement: { criteria: "classification_count" },
                     aggregation: { public: true },
                     configuration: { autoplay_subjects: true },
                     public_gold_standard: true,
                     tasks: create_task_params,
                     grouped: true,
                     prioritized: true,
                     primary_language: 'en',
                     display_order_position: 1,
                     links: { project: project.id.to_s }
                    }
      }
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

    context "extracts strings from workflow" do
      it 'should replace "Draw a circle" with 0' do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
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

    it_behaves_like "is destructable"
  end

  describe "#show" do
    let(:resource) { workflows.first }

    it_behaves_like "is showable"

    context "with a logged in user" do
      it "should not load a user's subject queue" do
        expect(EnqueueSubjectQueueWorker).not_to receive(:perform_async)
        default_request scopes: scopes, user_id: authorized_user.id
        get :show, id: resource.id
      end
    end

    context "with a logged out user" do
      it "should not load the general subject queue" do
        expect(EnqueueSubjectQueueWorker).not_to receive(:perform_async)
        get :show, id: resource.id
      end
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

    it 'returns a 200 status' do
      post :retire_subjects, workflow_id: workflow.id, subject_id: subject.id
      expect(response.status).to eq(200)
    end

    it 'retires the subject' do
      post :retire_subjects, workflow_id: workflow.id, subject_id: subject.id
      expect(subject.retired_for_workflow?(workflow)).to be_truthy
    end

    it 'queues a cellect retirement if the workflow uses cellect' do
      allow(Panoptes).to receive(:use_cellect?).and_return(true)
      expect(RetireCellectWorker).to receive(:perform_async).with(subject.id, workflow.id)
      post :retire_subjects, workflow_id: workflow.id, subject_id: subject.id
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
end
