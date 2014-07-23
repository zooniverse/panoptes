require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let(:user) { create(:user) }
  let!(:workflows){ create_list :workflow_with_subjects, 2 }
  let(:workflow){ workflows.first }
  let(:project){ workflow.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'workflows' }

  let(:api_resource_attributes){ %w(id name tasks classifications_count subjects_count created_at updated_at) }
  let(:api_resource_links){ %w(workflows.project workflows.subject_sets) }

  before(:each) do
    default_request scopes: %w(public project)
  end

  describe '#index' do
    before(:each){ get :index }

    it 'should return 200' do
      expect(response.status).to eq 200
    end

    it 'should have 2 items by default' do
      expect(json_response[api_resource_name].length).to eq 2
    end

    it_behaves_like 'an api response'
  end

  describe '#update' do
    it 'should be implemented'
  end

  describe '#create' do
    let(:created_workflow_id) { created_instance_id("workflows") }

    before(:each) do
      default_request scopes: %w(public project), user_id: owner.id
      params = {
        workflow: {
          name: 'Test workflow',
          tasks: [{ foo: 'bar' }, { bar: 'baz' }],
          project_id: project.id,
          grouped: true,
          prioritized: true,
          primary_language: 'en'
        }
      }
      post :create, params
    end

    it "should return 201" do
      expect(response.status).to eq(201)
    end

    it 'should create the new workflow' do
      created = Workflow.find(created_workflow_id)
      expect(created.name).to eq 'Test workflow'
      expect(created.tasks).to eq [{ 'foo' => 'bar' }, { 'bar' => 'baz' }]
    end

    it "should set the Location header as per JSON-API specs" do
      id = created_workflow_id
      expect(response.headers["Location"]).to eq("http://test.host/api/workflows/#{id}")
    end

    it_behaves_like 'an api response'
  end

  describe '#destroy' do
    before(:each) do
      default_request scopes: %w(public project), user_id: owner.id
      params = {
        id: workflow.id
      }
      delete :destroy, params
    end

    it 'should delete a workflow' do
      expect(response.status).to eq 204
      expect{ workflow.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "#show" do

    context "with a logged in user" do
      before(:each) do
        default_request user_id: user.id, scopes: %(project public)
        get :show, id: workflows.first.id
      end

      it "should return 200" do
        expect(response.status).to eq(200)
      end

      it "should return the requested worklow" do
        expect(json_response[api_resource_name].length).to eq(1)
        expect(json_response[api_resource_name][0]['id']).to eq(workflows.first.id.to_s)
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

      it_behaves_like "an api response"
    end

    context "without a logged in user" do
      it "should not send a load user command to cellect" do
        expect(stubbed_cellect_connection).to_not receive(:load_user)
        default_request scopes: %w(public project)
        get :show, id: workflows.first.id
      end
    end
  end
end
