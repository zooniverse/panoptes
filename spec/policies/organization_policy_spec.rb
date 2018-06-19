require 'spec_helper'

describe OrganizationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:listed_organization) { build(:organization, listed_at: Time.now, owner: resource_owner) }
    let(:unlisted_organization) { build(:unlisted_organization, owner: resource_owner) }

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

    describe 'update, destroy, update_links, destroy_links' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Organization).scope_for(:update)
      end

      context 'for an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it "includes nothing" do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to be_empty
        end
      end

      context 'for a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it "includes nothing" do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to be_empty
        end
      end

      context 'for the resource owner' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it "includes owned organizations" do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to include(listed_organization, unlisted_organization)
        end
      end

      context 'for an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'includes all organizations' do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to include(listed_organization, unlisted_organization)
        end
      end
    end

    describe 'translate' do
      let(:resolved_scope) do
        Pundit.policy!(api_user, Organization).scope_for(:translate)
      end

      context 'for an anonymous user' do
        let(:api_user) { ApiUser.new(anonymous_user) }

        it "includes nothing" do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to be_empty
        end
      end

      context 'for a normal user' do
        let(:api_user) { ApiUser.new(logged_in_user) }

        it "includes nothing" do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to be_empty
        end
      end

      context 'for the resource owner' do
        let(:api_user) { ApiUser.new(resource_owner) }

        it "includes owned organizations" do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to include(listed_organization, unlisted_organization)
        end
      end

      context 'for a translator' do
        let(:translator) { create(:user) }
        let(:api_user) { ApiUser.new(translator) }

        it "includes owned organizations" do
          listed_organization.save!
          unlisted_organization.save!

          create :access_control_list, user_group: translator.identity_group, resource: listed_organization, roles: ['translator']
          create :access_control_list, user_group: translator.identity_group, resource: unlisted_organization, roles: ['translator']

          expect(resolved_scope).to include(listed_organization, unlisted_organization)
        end
      end

      context 'for an admin' do
        let(:admin_user) { create :user, admin: true }
        let(:api_user) { ApiUser.new(admin_user, admin: true) }

        it 'includes all organizations' do
          listed_organization.save!
          unlisted_organization.save!
          expect(resolved_scope).to include(listed_organization, unlisted_organization)
        end
      end
    end
  end
end
