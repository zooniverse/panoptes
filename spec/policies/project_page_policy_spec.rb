require 'spec_helper'

describe ProjectPagePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_project_page) { build(:project_page, project: public_project) }
    let(:private_project_page) { build(:project_page, project: private_project) }

    subject do
      PunditScopeTester.new(ProjectPage, api_user)
    end

    before do
      public_project_page.save!
      private_project_page.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([public_project_page]) }
      its(:show) { is_expected.to match_array([public_project_page]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([public_project_page]) }
      its(:version) { is_expected.to match_array([public_project_page]) }
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([public_project_page]) }
      its(:show) { is_expected.to match_array([public_project_page]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([public_project_page]) }
      its(:version) { is_expected.to match_array([public_project_page]) }
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([public_project_page, private_project_page]) }
      its(:show) { is_expected.to match_array([public_project_page, private_project_page]) }
      its(:update) { is_expected.to match_array([private_project_page]) }
      its(:destroy) { is_expected.to match_array([private_project_page]) }
      its(:translate) { is_expected.to match_array([private_project_page]) }
      its(:versions) { is_expected.to match_array([public_project_page, private_project_page]) }
      its(:version) { is_expected.to match_array([public_project_page, private_project_page]) }
    end

    context 'for a translator user' do
      let(:api_user) { ApiUser.new(logged_in_user) }
      before do
        create(
          :access_control_list,
          resource: private_project,
          user_group: logged_in_user.identity_group,
          roles: ["translator"]
        )
      end

      its(:index) { is_expected.to match_array([public_project_page, private_project_page]) }
      its(:show) { is_expected.to match_array([public_project_page, private_project_page]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to match_array([private_project_page]) }
      its(:versions) { is_expected.to match_array([public_project_page, private_project_page]) }
      its(:version) { is_expected.to match_array([public_project_page, private_project_page]) }
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }
      let(:all_project_pages) do
        [public_project_page, private_project_page]
      end

      its(:index) { is_expected.to match_array(all_project_pages) }
      its(:show) { is_expected.to match_array(all_project_pages) }
      its(:update) { is_expected.to match_array(all_project_pages) }
      its(:destroy) { is_expected.to match_array(all_project_pages) }
      its(:translate) { is_expected.to match_array(all_project_pages) }
      its(:versions) { is_expected.to match_array(all_project_pages) }
      its(:version) { is_expected.to match_array(all_project_pages) }
    end
  end
end
