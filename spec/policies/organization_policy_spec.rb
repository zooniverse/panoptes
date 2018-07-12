require 'spec_helper'

describe OrganizationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:listed_organization) { build(:organization, listed_at: Time.now, owner: resource_owner) }
    let(:unlisted_organization) { build(:unlisted_organization, owner: resource_owner) }

    before do
      listed_organization.save!
      unlisted_organization.save!

      create :unlisted_organization # Should never be seen by anyone
    end

    subject do
      PunditScopeTester.new(Organization, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array(listed_organization) }
      its(:show) { is_expected.to match_array(listed_organization) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array(listed_organization) }
      its(:version) { is_expected.to match_array(listed_organization) }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array(listed_organization) }
      its(:show) { is_expected.to match_array(listed_organization) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array(listed_organization) }
      its(:version) { is_expected.to match_array(listed_organization) }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a tester' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: listed_organization, roles: ['tester']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: unlisted_organization, roles: ['tester']
      end

      its(:index) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:show) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:version) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a translator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: listed_organization, roles: ['translator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: unlisted_organization, roles: ['translator']
      end

      its(:index) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:show) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:version) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:translate) { is_expected.to match_array([listed_organization, unlisted_organization]) }
    end

    context 'as a scientist' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: listed_organization, roles: ['scientist']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: unlisted_organization, roles: ['scientist']
      end

      its(:index) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:show) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:version) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a moderator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: listed_organization, roles: ['moderator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: unlisted_organization, roles: ['moderator']
      end

      its(:index) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:show) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:version) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:translate) { is_expected.to be_empty }
    end

    context 'as a collaborator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: listed_organization, roles: ['collaborator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: unlisted_organization, roles: ['collaborator']
      end

      its(:index) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:show) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:destroy) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update_links) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:destroy_links) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:versions) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:version) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:translate) { is_expected.to match_array([listed_organization, unlisted_organization]) }
    end

    context 'as the owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:show) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:destroy) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:update_links) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:destroy_links) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:versions) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:version) { is_expected.to match_array([listed_organization, unlisted_organization]) }
      its(:translate) { is_expected.to match_array([listed_organization, unlisted_organization]) }
    end
  end
end
