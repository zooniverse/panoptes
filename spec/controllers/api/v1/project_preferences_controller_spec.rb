require 'spec_helper'

RSpec.describe Api::V1::ProjectPreferencesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:project) { create(:project) }

  let!(:upps) do
    create_list :user_project_preference, 2, user: authorized_user
  end

  let(:api_resource_name) { 'project_preferences' }
  let(:api_resource_attributes) { %w(id email_communication preferences href activity_count activity_count_by_workflow settings) }
  let(:api_resource_links) { %w(project_preferences.user project_preferences.project) }

  let(:scopes) { %w(public project) }
  let(:resource) { upps.first }
  let(:resource_class) { UserProjectPreference }

  describe "#index" do
    let!(:private_resource) { create(:user_project_preference) }
    let(:n_visible) { 2 }

    it_behaves_like "is indexable"

    describe "include projects" do
      before(:each) do
        default_request scopes: scopes, user_id: authorized_user.id
        get :index, include: "project"
      end

      it 'should be able to include linked projects' do
        expect(response).to have_http_status(:ok)
      end

      it 'should return the projects as links' do
        expect(json_response['linked']['projects']).to_not be_empty
      end
    end
  end

  describe "#show" do

    it_behaves_like "is showable"
  end

  describe "#update" do
    let(:unauthorized_user) { resource.project.owner }
    let(:test_attr) { :email_communication }
    let(:test_attr_value) { false }
    let(:update_params) do
      { project_preferences: { email_communication: false, settings: { workflow_id: 1234 } } }
    end

    it_behaves_like "is updatable"
  end

  describe "#create" do
    let(:test_attr) { :preferences }
    let(:test_attr_value) { { "tutorial" => true } }
    let(:create_params) do
      {
        project_preferences: {
          preferences: { tutorial: true },
          links: {
            project: project.id.to_s
          }
        }
      }
    end

    it_behaves_like "is creatable"
  end

  describe "#update_settings" do
    let!(:project) { create(:project, owner: authorized_user) }
    let!(:upp) { create(:user_project_preference, project: project) }
    let(:settings_params) do
      {
        project_preferences: {
          user_id: upp.user_id,
          project_id: project.id,
          settings: { workflow_id: 1234, designator: {subject_set_weights: {1 => 100, 2 => 1000}} }
        }
      }
    end
    let(:run_update) { post :update_settings, settings_params }

    before(:each) do
      default_request user_id: authorized_user.id, scopes: scopes
    end

    it "responds with a 200" do
      run_update
      expect(response.status).to eq(200)
    end

    it "responds with the updated resource" do
      run_update
      updated_upp = json_response[api_resource_name].first
      expect(updated_upp).not_to be_empty
      modified_dt = upp.updated_at.httpdate.to_datetime
      response_dt = response.headers['Last-Modified'].to_datetime
      expect(response_dt).to be_within(1.second).of(modified_dt)
    end

    it "updates the UPP settings attribute" do
      run_update
      found = UserProjectPreference.where(project: project, user: upp.user).first
      expect(found.settings["workflow_id"]).to eq(settings_params[:project_preferences][:settings][:workflow_id].to_s)
    end

    it "allows collaborators to update UPP" do
      collab = create(:user)
      create(:access_control_list,
             resource: project,
             user_group: collab.identity_group,
             roles: ["collaborator"])
      default_request user_id: collab.id, scopes: scopes
      run_update
      expect(response.status).to eq(200)
    end

    describe "trying to update attribute we aren't allowed to" do
      let(:settings_params) do
        {
          project_preferences: {
            user_id: upp.user_id,
            project_id: project.id,
            preferences: { mail_me_all_the_time: true }
          }
        }
      end

      it "cannot update preferences" do
        run_update
        expect(response.status).to eq(422)
      end
    end

    describe "trying to update a project we don't have rights on" do
      let(:unowned_project) { create(:project) }
      let(:new_upp) do
        create(:user_project_preference, project: unowned_project)
      end
      let(:settings_params) do
        {
          project_preferences: {
            user_id: new_upp.user_id,
            project_id: unowned_project.id,
            settings: { workflow_id: 1234 }
          }
        }
      end

      it "only updates settings of owned project" do
        run_update
        expect(response.status).to eq(403)
      end
    end

    describe "trying to update a resource that doesn't exist" do
      let(:unused_project) { create(:project) }
      let(:settings_params) do
        {
          project_preferences: {
            user_id: unused_project.owner.id,
            project_id: unused_project.id,
            settings: { workflow_id: 1234 }
          }
        }
      end

      it "responds with a 404 if UPP not found" do
        run_update
        expect(response.status).to eq(404)
      end
    end
  end
end
