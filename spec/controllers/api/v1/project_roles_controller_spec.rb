require 'spec_helper'

RSpec.describe Api::V1::ProjectRolesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:project) { create(:project, owner: authorized_user) }
  
  let!(:upps) do
    create_list :user_project_preference, 2, project: project,
      roles: ["tester"]
  end
  
  let(:api_resource_name) { 'project_roles' }
  let(:api_resource_attributes) { %w(id roles) }
  let(:api_resource_links) { %w(project_roles.user project_roles.project) }

  let(:scopes) { %w(public project) }
  let(:resource) { upps.first }
  let(:resource_class) { UserProjectPreference }


  describe "#index" do
    let!(:private_resource) { create(:user_project_preference) }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:test_attr) { :roles }
    let(:test_attr_value) { %w(collaborator) }
    let(:update_params) do
      { project_roles: { roles: ["collaborator"] } }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :roles }
    let(:test_attr_value) { ["collaborator"] }
    context "when a user has preferences for a project" do
      let(:create_params) do
        {
         project_roles: {
                         roles: ["collaborator"],
                         links: {
                                 user: create(:user).id.to_s,
                                 project: project.id.to_s
                                }
                        }
        }
      end

      it_behaves_like "is creatable"
    end

    context "when a user doesn't have preferences for a project" do
      let(:unauthorized_user) { resource.user }
      let(:create_params) do
        {
         project_roles: {
                         roles: ["collaborator"],
                         links: {
                                 user: resource.user.id.to_s,
                                 project: resource.project.id.to_s
                                }
                        }
        }
      end

      it_behaves_like "is creatable"
    end
  end
end
