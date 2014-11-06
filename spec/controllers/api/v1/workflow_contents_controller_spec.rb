require 'spec_helper'

RSpec.describe Api::V1::WorkflowContentsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:workflow) { create(:workflow_with_contents) }
  let!(:upp) do
    create(:user_project_preference,
           user: authorized_user,
           project: workflow.project,
           roles: ["translator"])
  end

  let(:api_resource_name) { 'workflow_contents' }
  let(:api_resource_attributes) { %w(id strings language) }
  let(:api_resource_links) { %w(workflow_contents.workflow) }

  let(:scopes) { %w(project) }
  let!(:resource) do
    create(:workflow_content, language: 'en-CA', workflow: workflow)
  end
  let(:resource_class) { WorkflowContent }
  let(:primary_content) { workflow.primary_content }

  describe "#index" do
    let!(:private_resource) do
      project = create(:project, visible_to: ["collaborator"])
      create(:workflow_with_contents, project: project)
        .workflow_contents.first
    end

    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#create" do
    let(:create_params) do
      {
        workflow_contents: {
          strings: %w(a bunch of strings),
          language: 'en-CA',
          links: {
            workflow: resource.workflow
          }
        }
      }
    end

    let(:test_attr) { :language }
    let(:test_attr_value) { 'en-CA' }

    it_behaves_like "is creatable"
  end

  
  describe "#update" do
    let(:update_params) do
      { workflow_contents: {
          strings: %w(new strings)
        }
      }
    end

    let(:test_attr) { :strings }
    let(:test_attr_value) { %w(new strings) }

    context "non-primary-language content" do
      it_behaves_like "is updatable"
    end

    context "primary-langauge content" do
      
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        params = update_params.merge(id: primary_content.id)
        put :update, params
      end
      
      it 'should return forbidden' do
        expect(response.status).to eq(403)
      end

      it 'should not update the content' do
        primary_content.reload
        expect(primary_content.strings).to_not eq(test_attr_value)
      end
    end
  end

  describe "#destroy" do
    let(:authorized_user) { workflow.project.owner }
    context "non-primary-language content" do
      it_behaves_like "is destructable"
    end

    context "primary-langauge content" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        delete :destroy, id: primary_content.id
      end
      
      it 'should return forbidden' do
        expect(response.status).to eq(403)
      end

      it 'should not delete the content' do
        expect(WorkflowContent.find(primary_content.id)).to eq(primary_content)
      end
    end
  end
  
  describe "versionsing" do
    let(:update_block) do
      11.times do |n|
        resource.update!(strings: [n.to_s])
      end
    end

    let(:resource_param) { :workflow_content_id }

    it_behaves_like "a versioned resource"
  end
end
