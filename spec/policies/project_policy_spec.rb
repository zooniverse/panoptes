require 'spec_helper'

describe ProjectPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project) { build(:project, owner: resource_owner) }
    let(:private_project) { build(:private_project, owner: resource_owner) }

    before do
      public_project.save!
      private_project.save!

      create :private_project # This should never be seen by anyone
    end

    subject do
      PunditScopeTester.new(Project, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array(public_project) }
      its(:show) { is_expected.to match_array(public_project) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array(public_project) }
      its(:version) { is_expected.to match_array(public_project) }
      its(:create_classifications_export) { is_expected.to be_empty }
      its(:create_subjects_export) { is_expected.to be_empty }
      its(:create_workflows_export) { is_expected.to be_empty }
      its(:create_workflow_contents_export) { is_expected.to be_empty }
      its(:retire_subjects) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array(public_project) }
      its(:show) { is_expected.to match_array(public_project) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array(public_project) }
      its(:version) { is_expected.to match_array(public_project) }
      its(:create_classifications_export) { is_expected.to be_empty }
      its(:create_subjects_export) { is_expected.to be_empty }
      its(:create_workflows_export) { is_expected.to be_empty }
      its(:create_workflow_contents_export) { is_expected.to be_empty }
      its(:retire_subjects) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a tester' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_project, roles: ['tester']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_project, roles: ['tester']
      end

      its(:index) { is_expected.to match_array([public_project, private_project]) }
      its(:show) { is_expected.to match_array([public_project, private_project]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([public_project, private_project]) }
      its(:version) { is_expected.to match_array([public_project, private_project]) }
      its(:create_classifications_export) { is_expected.to be_empty }
      its(:create_subjects_export) { is_expected.to be_empty }
      its(:create_workflows_export) { is_expected.to be_empty }
      its(:create_workflow_contents_export) { is_expected.to be_empty }
      its(:retire_subjects) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a translator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_project, roles: ['translator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_project, roles: ['translator']
      end

      its(:index) { is_expected.to match_array([public_project, private_project]) }
      its(:show) { is_expected.to match_array([public_project, private_project]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([public_project, private_project]) }
      its(:version) { is_expected.to match_array([public_project, private_project]) }
      its(:create_classifications_export) { is_expected.to be_empty }
      its(:create_subjects_export) { is_expected.to be_empty }
      its(:create_workflows_export) { is_expected.to be_empty }
      its(:create_workflow_contents_export) { is_expected.to be_empty }
      its(:retire_subjects) { is_expected.to be_empty }
      its(:translate) { is_expected.to match_array([public_project, private_project]) }
    end

    context 'as a scientist' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_project, roles: ['scientist']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_project, roles: ['scientist']
      end

      its(:index) { is_expected.to match_array([public_project, private_project]) }
      its(:show) { is_expected.to match_array([public_project, private_project]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([public_project, private_project]) }
      its(:version) { is_expected.to match_array([public_project, private_project]) }
      its(:create_classifications_export) { is_expected.to be_empty }
      its(:create_subjects_export) { is_expected.to be_empty }
      its(:create_workflows_export) { is_expected.to be_empty }
      its(:create_workflow_contents_export) { is_expected.to be_empty }
      its(:retire_subjects) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a moderator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_project, roles: ['moderator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_project, roles: ['moderator']
      end

      its(:index) { is_expected.to match_array([public_project, private_project]) }
      its(:show) { is_expected.to match_array([public_project, private_project]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([public_project, private_project]) }
      its(:version) { is_expected.to match_array([public_project, private_project]) }
      its(:create_classifications_export) { is_expected.to be_empty }
      its(:create_subjects_export) { is_expected.to be_empty }
      its(:create_workflows_export) { is_expected.to be_empty }
      its(:create_workflow_contents_export) { is_expected.to be_empty }
      its(:retire_subjects) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a collaborator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_project, roles: ['collaborator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_project, roles: ['collaborator']
      end

      its(:index) { is_expected.to match_array([public_project, private_project]) }
      its(:show) { is_expected.to match_array([public_project, private_project]) }
      its(:update) { is_expected.to match_array([public_project, private_project]) }
      its(:destroy) { is_expected.to match_array([public_project, private_project]) }
      its(:update_links) { is_expected.to match_array([public_project, private_project]) }
      its(:destroy_links) { is_expected.to match_array([public_project, private_project]) }
      its(:versions) { is_expected.to match_array([public_project, private_project]) }
      its(:version) { is_expected.to match_array([public_project, private_project]) }
      its(:create_classifications_export) { is_expected.to match_array([public_project, private_project]) }
      its(:create_subjects_export) { is_expected.to match_array([public_project, private_project]) }
      its(:create_workflows_export) { is_expected.to match_array([public_project, private_project]) }
      its(:create_workflow_contents_export) { is_expected.to match_array([public_project, private_project]) }
      its(:retire_subjects) { is_expected.to match_array([public_project, private_project]) }
      its(:translate) { is_expected.to match_array([public_project, private_project]) }
    end

    context 'as the owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([public_project, private_project]) }
      its(:show) { is_expected.to match_array([public_project, private_project]) }
      its(:update) { is_expected.to match_array([public_project, private_project]) }
      its(:destroy) { is_expected.to match_array([public_project, private_project]) }
      its(:update_links) { is_expected.to match_array([public_project, private_project]) }
      its(:destroy_links) { is_expected.to match_array([public_project, private_project]) }
      its(:versions) { is_expected.to match_array([public_project, private_project]) }
      its(:version) { is_expected.to match_array([public_project, private_project]) }
      its(:create_classifications_export) { is_expected.to match_array([public_project, private_project]) }
      its(:create_subjects_export) { is_expected.to match_array([public_project, private_project]) }
      its(:create_workflows_export) { is_expected.to match_array([public_project, private_project]) }
      its(:create_workflow_contents_export) { is_expected.to match_array([public_project, private_project]) }
      its(:retire_subjects) { is_expected.to match_array([public_project, private_project]) }
      its(:translate) { is_expected.to match_array([public_project, private_project]) }
    end
  end
end
