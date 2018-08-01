require 'spec_helper'

describe ProjectPagePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_project_page) { build(:project_page, project: public_project) }
    let(:private_project_page) { build(:project_page, project: private_project) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, ProjectPage).scope_for(:index)
    end

    before do
      public_project_page.save!
      private_project_page.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes project_pages from public projects" do
        expect(resolved_scope).to match_array(public_project_page)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes project_pages from public projects" do
        expect(resolved_scope).to match_array(public_project_page)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes project_pages from public projects" do
        expect(resolved_scope).to include(public_project_page)
      end

      it 'includes project_pages from owned private projects' do
        expect(resolved_scope).to include(private_project_page)
      end
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

      it "includes project_pages from private translation projects" do
        resolved_scope = Pundit.policy!(api_user, ProjectPage).scope_for(:translate)
        expect(resolved_scope).to match_array(private_project_page)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_project_page, private_project_page)
      end
    end
  end
end
