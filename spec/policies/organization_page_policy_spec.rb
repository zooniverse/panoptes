require 'spec_helper'

describe OrganizationPagePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:listed_organization)  { build(:organization) }
    let(:unlisted_organization) { build(:organization, owner: resource_owner, listed: false) }

    let(:listed_organization_page) { build(:organization_page, organization: listed_organization) }
    let(:unlisted_organization_page) { build(:organization_page, organization: unlisted_organization) }

    subject do
      PunditScopeTester.new(OrganizationPage, api_user)
    end

    before do
      listed_organization_page.save!
      unlisted_organization_page.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([listed_organization_page]) }
      its(:show) { is_expected.to match_array([listed_organization_page]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([listed_organization_page]) }
      its(:version) { is_expected.to match_array([listed_organization_page]) }
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([listed_organization_page]) }
      its(:show) { is_expected.to match_array([listed_organization_page]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
      its(:versions) { is_expected.to match_array([listed_organization_page]) }
      its(:version) { is_expected.to match_array([listed_organization_page]) }
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
      its(:show) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
      its(:update) { is_expected.to match_array([unlisted_organization_page]) }
      its(:destroy) { is_expected.to match_array([unlisted_organization_page]) }
      its(:translate) { is_expected.to match_array([unlisted_organization_page]) }
      its(:versions) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
      its(:version) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
    end

    context 'for a translator user' do
      let(:api_user) { ApiUser.new(logged_in_user) }
      before do
        create(
          :access_control_list,
          resource: unlisted_organization,
          user_group: logged_in_user.identity_group,
          roles: ["translator"]
        )
      end

      its(:index) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
      its(:show) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to match_array([unlisted_organization_page]) }
      its(:versions) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
      its(:version) { is_expected.to match_array([unlisted_organization_page, listed_organization_page]) }
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }
      let(:all_organization_pages) do
        [unlisted_organization_page, listed_organization_page]
      end

      its(:index) { is_expected.to match_array(all_organization_pages) }
      its(:show) { is_expected.to match_array(all_organization_pages) }
      its(:update) { is_expected.to match_array(all_organization_pages) }
      its(:destroy) { is_expected.to match_array(all_organization_pages) }
      its(:translate) { is_expected.to match_array(all_organization_pages) }
      its(:versions) { is_expected.to match_array(all_organization_pages) }
      its(:version) { is_expected.to match_array(all_organization_pages) }
    end
  end
end
