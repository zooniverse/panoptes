require 'spec_helper'

describe OrganizationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:listed_organization) { build(:organization, listed_at: Time.now, owner: resource_owner) }
    let(:unlisted_organization) { build(:unlisted_organization, owner: resource_owner) }

    let(:api_resource_name) { "organizations" }
    let(:scopes) { %w(public organization) }

    describe 'index, show, versions, version' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Organization).scope_for(:index)
      end

      context 'for an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it "includes listed organizations" do
          listed_organization.save!
          expect(resolved_scope).to include(listed_organization)
        end

        it 'should not include private resources' do
          unlisted_organization.save!
          expect(resolved_scope).not_to include(unlisted_organization)
        end
      end

      context 'for a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it "includes listed organizations" do
          listed_organization.save!
          expect(resolved_scope).to include(listed_organization)
        end

        it 'should not include private resources' do
          unlisted_organization.save!
          expect(resolved_scope).not_to include(unlisted_organization)
        end
      end

      context 'for the resource owner' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it "includes listed organizations" do
          listed_organization.save!
          expect(resolved_scope).to include(listed_organization)
        end

        it 'includes owned resources' do
          unlisted_organization.save!
          expect(resolved_scope).to include(unlisted_organization)
        end
      end

      context 'for an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'should include the non-visible resource' do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to include(listed_organization, unlisted_organization)
        end
      end
    end
  end
end
