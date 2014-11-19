require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let(:user) { create(:user) }
  let(:workflows){ create_list :workflow_with_contents, 2 }
  let(:workflow){ workflows.first }
  let(:project){ workflow.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'workflows' }
  let(:resource_class) { Workflow }
  let(:authorized_user) { owner }

  let(:api_resource_attributes) do
    %w(id name tasks classifications_count subjects_count created_at updated_at first_task primary_language content_language version)
  end
  let(:api_resource_links){ %w(workflows.project workflows.subject_sets) }
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
    let(:test_attr) { :name }
    let(:test_attr_value) { "A Better Name" }
    let(:test_relation) { :subject_sets }
    let(:test_relation_ids) { subject_set.id }
    let(:update_params) do
      {
        workflows: {
          name: "A Better Name",
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
    let(:test_attr) { :name }
    let(:test_attr_value) { 'Test workflow' }
    let(:create_params) do
      {
        workflows: {
          name: 'Test workflow',
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
            project: project.id,
          }
        }
      }
    end

    it_behaves_like "is creatable"

    context "extracts strings from workflow" do
      it 'should replace "Draw a circle" with 0' do
        default_request scopes: scopes, user_id: authorized_user.id
        post :create, create_params
        instance = Workflow.find(created_instance_id(api_resource_name))
        expect(instance.tasks["interest"]["question"]).to eq("interest.question")
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
      before(:each) do
        default_request user_id: user.id, scopes: scopes
        get :show, id: workflows.first.id
      end

      it "should set the cellect host for the user and workflow" do
        user.reload
        expect(session[:cellect_hosts]).to include( workflows.first.id.to_s )
        expect(session[:cellect_hosts][workflows.first.id.to_s]).to eq("example.com")
      end

      it "should set a load user command to cellect" do
        expect(stubbed_cellect_connection).to receive(:load_user)
                                               .with(user_id: user.id,
                                                     host: 'example.com',
                                                     workflow_id: workflows.first.id.to_s)
        get :show, id: workflows.first.id
      end
    end

    context "without a logged in user" do
      it "should not send a load user command to cellect" do
        expect(stubbed_cellect_connection).to_not receive(:load_user)
        default_request scopes: %w(public project)
        get :show, id: workflows.first.id
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
