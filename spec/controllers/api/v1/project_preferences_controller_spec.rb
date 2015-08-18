require 'spec_helper'

RSpec.describe Api::V1::ProjectPreferencesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:project) { create(:project) }

  let!(:upps) do
    create_list :user_project_preference, 2, user: authorized_user
  end

  let(:api_resource_name) { 'project_preferences' }
  let(:api_resource_attributes) { %w(id email_communication preferences href activity_count) }
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

    context "when the upp has no activity count" do
      let(:project) { create(:project_with_workflow) }
      let!(:upps) do
        [create(:user_project_preference, user: authorized_user, project: project)]
      end
      let!(:user_seens) do
        create(:user_seen_subject, user: authorized_user,
          workflow: project.workflows.first, build_real_subjects: false)
      end

      let(:run_get) do
        allow_any_instance_of(UserProjectPreference).to receive(:activity_count).and_return(nil)
        default_request scopes: scopes, user_id: authorized_user.id
        get :show, id: resource.id
      end

      it "should return the correct count from user seen subjects" do
        run_get
        expected_count = created_instance(api_resource_name)["activity_count"]
        expect(expected_count).to eq(user_seens.subject_ids.size)
      end

      context "when the user has classified on more than 1 project" do

        it "should return the specific project activity count from user seen subjects" do
          create(:user_seen_subject, user: authorized_user, build_real_subjects: false)
          run_get
          expected_count = created_instance(api_resource_name)["activity_count"]
          expect(expected_count).to eq(user_seens.subject_ids.size)
        end
      end

      context "when the user has legacy counts" do
        let!(:upps) do
          [create(:legacy_user_project_preference, user: authorized_user, project: project)]
        end

        it "should return the summated counts for each legacy workflow" do
          run_get
          result_count = created_instance(api_resource_name)["activity_count"]
          expected_count = upps.map{ |upp| upp.legacy_count.values.sum }.sum
          expect(expected_count).to eq(expected_count)
        end
      end

      context "when the user has busted legacy counts" do
        let!(:upps) do
          [create(:busted_legacy_user_project_preference, user: authorized_user, project: project)]
        end

        it "should return the summated counts for each valid legacy workflow" do
          run_get
          result_count = created_instance(api_resource_name)["activity_count"]
          expected_count = upps.map{ |upp| upp.send(:valid_legacy_count_values).sum }.sum
          expect(expected_count).to eq(expected_count)
        end
      end
    end
  end

  describe "#update" do
    let(:unauthorized_user) { resource.project.owner }
    let(:test_attr) { :email_communication }
    let(:test_attr_value) { false }
    let(:update_params) do
      { project_preferences: { email_communication: false } }
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
end
