require 'spec_helper'

describe Api::V1::WorkflowsController, type: :controller do
  let(:user) { create(:user) }
  let!(:workflows){ create_list :workflow_with_subjects, 2 }
  let(:workflow){ workflows.first }
  let(:project){ workflow.project }
  let(:owner){ project.owner }
  let(:api_resource_name){ 'workflows' }
  let(:resource_class) { Workflow }
  let(:authorized_user) { owner }

  let(:api_resource_attributes){ %w(id name tasks classifications_count subjects_count created_at updated_at) }
  let(:api_resource_links){ %w(workflows.project workflows.subject_sets) }
  let(:scopes) { %w(public project) }

  before(:each) do
    default_request scopes: scopes
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
    let(:test_attr) { :name }
    let(:test_attr_value) { 'Test workflow' }
    let(:create_params) do
      {
       workflows: {
                   name: 'Test workflow',
                   tasks: [{ foo: 'bar' }, { bar: 'baz' }],
                   project_id: project.id,
                   grouped: true,
                   prioritized: true,
                   primary_language: 'en'
                  }
      }
    end
    
    it_behaves_like "is creatable"
  end

  describe '#destroy' do
    let(:resource) { workflow }

    it_behaves_like "is destructable"
  end

  describe "#show" do

    context "with a logged in user" do
      before(:each) do
        default_request user_id: user.id, scopes: scopes
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
