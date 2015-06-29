require 'spec_helper'

RSpec.describe Api::V1::ProjectContentsController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:project) { create(:project_with_contents) }
  let(:api_resource_name) { 'project_contents' }
  let(:api_resource_attributes) do
    %w(id title description introduction language workflow_description)
  end
  let(:api_resource_links) { %w(project_contents.project) }

  let(:scopes) { %w(project) }
  let!(:resource) do
    create(:project_content, language: "en-CA", project: project)
  end
  let(:resource_class) { ProjectContent }
  let(:primary_content) { project.primary_content }

  describe "#index" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: project,
             roles: ["translator"])
    end

    let!(:private_resource) do
      create(:project_with_contents, private: true)
        .project_contents.first
    end

    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: project,
             roles: ["translator"])
    end

    it_behaves_like "is showable"
  end

  describe "#create" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: project,
             roles: ["translator"])
    end


    let(:create_params) do
      { project_contents: {
          title: "A Bad Title",
          description: "Worse Content",
          introduction: "Useless Science",
          language: "en-CA",
          workflow_description: "some more text",
          links: { project: project.id.to_s }
        }
      }
    end

    let(:test_attr) { :title }
    let(:test_attr_value) { "A Bad Title" }

    it_behaves_like "is creatable"
  end

  describe "#update" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: project,
             roles: ["translator"])
    end


    let(:update_params) do
      { project_contents: {
          workflow_description: "some more text"
        }
      }
    end

    let(:test_attr) { :workflow_description }
    let(:test_attr_value) { "some more text" }

    context "non-primary-language content" do
      it_behaves_like "is updatable"
    end

    context "primary-language content" do
      context "primary-langauge content" do

        before(:each) do
          default_request user_id: authorized_user.id, scopes: scopes
          params = update_params.merge(id: primary_content.id)
          put :update, params
        end

        it 'should return forbidden' do
          expect(response).to have_http_status(:not_found)
        end

        it 'should not update the content' do
          primary_content.reload
          expect(primary_content.workflow_description).to_not eq(test_attr_value)
        end
      end
    end
  end

  describe "#destroy" do
    let(:authorized_user) { project.owner }
    context "non-primary-language content" do
      it_behaves_like "is destructable"
    end

    context "primary-langauge content" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        delete :destroy, id: primary_content.id
      end

      it 'should return forbidden' do
        expect(response).to have_http_status(:not_found)
      end

      it 'should not delete the content' do
        expect(ProjectContent.find(primary_content.id)).to eq(primary_content)
      end
    end
  end

  describe "versioning" do
    let!(:acl) do
      create(:access_control_list,
             user_group: authorized_user.identity_group,
             resource: project,
             roles: ["translator"])
    end


    let!(:existing_versions) { resource.versions.length }
    let(:num_times) { 11 }
    let(:update_proc) { Proc.new { |resource, n| resource.update!(title: n.to_s) } }
    let(:resource_param) { :project_content_id }

    it_behaves_like "a versioned resource"
  end
end
