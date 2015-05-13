require 'spec_helper'

RSpec.describe Api::V1::ProjectPreferencesController, type: :controller do
  let(:authorized_user) { create(:user) }
  let(:project) { create(:project) }

  let!(:upps) do
    create_list :user_project_preference, 2, user: authorized_user,
      email_communication: true
  end

  let(:api_resource_name) { 'project_preferences' }
  let(:api_resource_attributes) { %w(id email_communication preferences) }
  let(:api_resource_links) { %w(project_preferences.user project_preferences.project) }

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
