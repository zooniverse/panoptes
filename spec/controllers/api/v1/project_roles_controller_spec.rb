require 'spec_helper'

RSpec.describe Api::V1::ProjectRolesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:project) { create(:project, owner: authorized_user) }

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

    it_behaves_like "it has custom owner links"

    context "when not logged in" do
      let(:project) { create(:project) }
      let(:authorized_user) { nil }

      it_behaves_like "is indexable"
    end

    describe "a logged in user" do

      it_behaves_like "is indexable"

      describe "filter params" do
        let!(:new_project) { create(:project) }

        before(:each) do
          default_request scopes: scopes, user_id: authorized_user.id if authorized_user
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
            user: user,
            project: project.id.to_s
          }
        }
      }
    end

    context "when the user exists" do
      let(:user) { create(:user).id.to_s }
      it_behaves_like "is creatable"
    end

    context "when the user has an acl" do
      let(:user) do
        u = create(:user)
        create(:access_control_list, user_group: u.identity_group, resource: project)
        u.id.to_s
      end

      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, create_params
      end

      it 'should return 400' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'should have an error message' do
        msg = json_response['errors'][0]['message']
        expect(msg).to match(/Roles have already been set for this user or group/)
      end
    end

    shared_examples "no user" do
      before(:each) do
        default_request user_id: authorized_user.id, scopes: scopes
        post :create, create_params
      end

      it 'should return 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'should have an error saying the user does not exist' do
        msg = json_response['errors'][0]['message']
        expect(msg).to match(/No User with id: [\-0-9]+ exists/)
      end
    end

    context "when the user does not exist" do
      let(:user) { "-1" }

      it_behaves_like "no user"
    end

    context "when the user exists but is inactive" do
      let(:user) do
        u = create(:user)
        u.disable!
        u.memberships.each(&:disable!)
        u.id.to_s
      end

      it_behaves_like "no user"
    end
  end

  describe "#destroy" do
    it_behaves_like "is destructable"
  end
end
