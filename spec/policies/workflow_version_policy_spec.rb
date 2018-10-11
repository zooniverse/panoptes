require 'spec_helper'

describe WorkflowVersionPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_workflow) { build(:workflow, project: public_project) }
    let(:private_workflow) { build(:workflow, project: private_project) }

    let(:public_workflow_version) { build(:workflow_version, workflow: public_workflow) }
    let(:private_workflow_version) { build(:workflow_version, workflow: private_workflow) }

    subject do
      PunditScopeTester.new(WorkflowVersion, api_user)
    end

    before do
      public_workflow_version.save!
      private_workflow_version.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array(public_workflow.workflow_versions) }
      its(:show) { is_expected.to match_array(public_workflow.workflow_versions) }
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array(public_workflow.workflow_versions) }
      its(:show) { is_expected.to match_array(public_workflow.workflow_versions) }
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array(private_workflow.workflow_versions + public_workflow.workflow_versions) }
      its(:show) { is_expected.to match_array(private_workflow.workflow_versions + public_workflow.workflow_versions) }
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      its(:index) { is_expected.to match_array(WorkflowVersion.all) }
      its(:show) { is_expected.to match_array(WorkflowVersion.all) }
    end
  end
end
