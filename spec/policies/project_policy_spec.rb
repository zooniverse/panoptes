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
      its(:unretire_subjects) { is_expected.to be_empty }
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
      its(:unretire_subjects) { is_expected.to be_empty }
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
      its(:unretire_subjects) { is_expected.to be_empty }
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
      its(:unretire_subjects) { is_expected.to be_empty }
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
      its(:unretire_subjects) { is_expected.to be_empty }
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
      its(:unretire_subjects) { is_expected.to be_empty }
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
      its(:unretire_subjects) { is_expected.to match_array([public_project, private_project]) }
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
      its(:unretire_subjects) { is_expected.to match_array([public_project, private_project]) }
      its(:translate) { is_expected.to match_array([public_project, private_project]) }
    end
  end

  describe "links" do
    let(:resource_owner) { create :user }
    let(:project) { create :project }
    let(:api_user) { ApiUser.new(resource_owner) }
    let(:policy) { ProjectPolicy.new(api_user, project) }

    it "should allow workflows to link when user has update permissions" do
      workflow_in_project = create :workflow, project: project
      workflow_other_project = create :workflow

      expect(policy.linkable_workflows).to match_array([workflow_in_project, workflow_other_project])
    end

    it "should allow subject_sets to link when user has update permissions" do
      subject_set_in_project = create :subject_set, project: project, num_workflows: 0
      subject_set_other_project = create :subject_set, num_workflows: 0

      expect(policy.linkable_subject_sets).to match_array([subject_set_in_project, subject_set_other_project])
    end

    # This is not part of the create/update schema for project
    # it "should allow subjects to link when user has update permissions" do
    #   expect(Project).to link_to(Subject).given_args(user)
    #                       .with_scope(:scope_for, :update, user)
    # end

    # There is not part of the create/update schema for project
    # it "should allow collections to link user has show permissions" do
    #   collection1 = create :collection, owner: resource_owner
    #   collection2 = create :collection
    #   collection3 = create :collection, private: true

    #   expect(policy.linkable_collections).to match_array([collection1, collection2])
    # end
  end
end
