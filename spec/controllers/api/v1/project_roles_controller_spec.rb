require 'spec_helper'

RSpec.describe Api::V1::ProjectRolesController, type: :controller do
  let(:user) { create(:user) }
  let(:authorized_user) { user }
  let(:project) { create(:project, owner: user) }

  let!(:acls) do
    create_list :access_control_list, 2, resource: project,
                roles: ["tester"]
  end

  let(:api_resource_name) { 'project_roles' }
  let(:api_resource_attributes) { %w(id roles) }
  let(:api_resource_links) { %w(project_roles.project) }

  let(:scopes) { %w(public project) }
  let(:resource) { acls.first }
  let(:resource_class) { AccessControlList }

  describe "#index" do
    let!(:private_resource) { create(:access_control_list, resource: create(:project, private: true)) }
    let(:n_visible) { 3 }

    context "when not logged in" do
      let(:authorized_user) { nil }

      it_behaves_like "is indexable"

      it "should have the custom owner resource links" do
        get :index
        resource_links = json_response[api_resource_name].map do |resource|
          resource["links"]["owner"].keys
        end
        expect(resource_links.flatten.uniq).to eq %w(id type href)
      end
    end

    describe "a logged in user" do

      it_behaves_like "is indexable"

      describe "filter params" do
        let!(:new_project) { create(:project) }

        before(:each) do
          get :index, index_options
        end

        describe "filter by project_id" do
          let(:index_options) { { project_id: new_project.id } }

          it "should respond with 1 item" do
            expect(json_response[api_resource_name].length).to eq(1)
          end

          it "should respond with the correct item" do
            project_id = json_response[api_resource_name][0]['links']['project']
            expect(project_id).to eq(new_project.id.to_s)
          end
        end
      end
    end
  end

  describe "#show" do
    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:unauthorized_user) { create(:user) }
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
end
