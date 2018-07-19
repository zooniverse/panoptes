require 'spec_helper'

describe FieldGuidePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_field_guide) { build(:field_guide, project: public_project) }
    let(:private_field_guide) { build(:field_guide, project: private_project) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, FieldGuide).scope_for(:index)
    end

    before do
      public_field_guide.save!
      private_field_guide.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "includes field_guides from public projects" do
        expect(resolved_scope).to match_array(public_field_guide)
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it "includes field_guides from public projects" do
        expect(resolved_scope).to match_array(public_field_guide)
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes field_guides from public projects" do
        expect(resolved_scope).to include(public_field_guide)
      end

      it 'includes field_guides from owned private projects' do
        expect(resolved_scope).to include(private_field_guide)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_field_guide, private_field_guide)
      end
    end
  end
end
