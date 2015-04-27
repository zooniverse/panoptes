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

  let(:api_resource_attributes) do
    %w(id display_name tasks classifications_count subjects_count created_at updated_at first_task primary_language content_language version grouped prioritized pairwise)
  end
  let(:api_resource_links){ %w(workflows.project workflows.subject_sets workflows.tutorial_subject workflows.expert_subject_set) }
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
    let(:private_project) { create(:private_project) }
    let!(:private_resource) { create(:workflow, project: private_project) }
    let(:n_visible) { 2 }

    it_behaves_like 'is indexable'
  end

  describe '#update' do
    let(:subject_set) { create(:subject_set, project: project) }
    let(:resource) { create(:workflow_with_contents, project: project) }
    let(:test_attr) { :display_name }
    let(:test_attr_value) { "A Better Name" }
    let(:test_relation) { :subject_sets }
    let(:test_relation_ids) { subject_set.id }
    let(:update_params) do
      {
        workflows: {
          display_name: "A Better Name",
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
  end

  describe '#create' do
    let(:test_attr) { :display_name }
    let(:test_attr_value) { 'Test workflow' }
    let(:create_params) do
      {
        workflows: {
          display_name: 'Test workflow',
          first_task: 'interest',
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
          },
          grouped: true,
          prioritized: true,
          primary_language: 'en',
          links: {
            project: project.id.to_s
          }
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

    context "creates an expert subject set" do
      let(:subject_set_id) { json_response["workflows"][0]["links"]["expert_subject_set"] }
      let(:instance) { SubjectSet.find(subject_set_id) }
      
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
      end
      
      it 'should have a link to the created set' do
        expect(subject_set_id).to_not be_nil
      end
      
      it 'should have expert_set flag set to true' do
        expect(instance.expert_set).to be_truthy
      end

      it 'should be named based on the workflow' do
        expect(instance.display_name).to eq("Expert Set for Test workflow")
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
  end

  describe '#destroy' do
    let(:resource) { workflow }

    it_behaves_like "is destructable"
  end

  describe "#show" do
    let(:resource) { workflows.first }

    it_behaves_like "is showable"

    context "with a logged in user" do
      it "should load a user's subject queue" do
        expect(SubjectQueueWorker).to receive(:perform_async).with(resource.id.to_s, user: authorized_user.id)
        default_request scopes: scopes, user_id: authorized_user.id
        get :show, id: resource.id
      end
    end

    context "with a logged out user" do
      it "should load the general subject queue" do
        expect(SubjectQueueWorker).to receive(:perform_async).with(resource.id.to_s, user: nil)
        get :show, id: resource.id
      end
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
