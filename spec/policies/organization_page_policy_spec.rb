require 'spec_helper'

describe OrganizationPagePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:listed_organization)  { build(:organization, owner: resource_owner) }
    let(:unlisted_organization) { build(:organization, owner: resource_owner, listed: false) }

    let(:listed_organization_page) { build(:organization_page, organization: listed_organization) }
    let(:unlisted_organization_page) { build(:organization_page, organization: unlisted_organization) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, OrganizationPage).scope_for(:index)
    end

    before do
      listed_organization_page.save!
      unlisted_organization_page.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes organization_pages from listed organizations" do
        expect(resolved_scope).to match_array(listed_organization_page)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes organization_pages from listed organizations" do
        expect(resolved_scope).to match_array(listed_organization_page)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes organization_pages from listed organizations" do
        expect(resolved_scope).to include(listed_organization_page)
      end

      it 'includes organization_pages from owned unlisted organizations' do
        expect(resolved_scope).to include(unlisted_organization_page)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(listed_organization_page, unlisted_organization_page)
      end
    end
  end
end
