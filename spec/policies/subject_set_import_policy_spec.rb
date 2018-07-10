require 'spec_helper'

describe SubjectSetImportPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:project) { build(:project, owner: resource_owner) }
    let(:subject_set) { build(:subject_set, project: project) }
    let(:subject_set_import) { build(:subject_set_import, subject_set: subject_set) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, SubjectSetImport).scope_for(:index)
    end

    before { subject_set_import.save }

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it "returns nothing" do
        expect(resolved_scope).to be_empty
      end
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it 'returns nothing' do
        expect(resolved_scope).to be_empty
      end
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it "includes all imports" do
        expect(resolved_scope).to include(subject_set_import)
      end
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'should include the non-visible resource' do
        expect(resolved_scope).to include(subject_set_import)
      end
    end
  end

  describe 'links' do
    let(:resource_owner) { create :user }
    let(:project) { create :project, owner: resource_owner }
    let(:subject_set) { create :subject_set, project: project }
    let(:subject_set_import) { build :subject_set_import, subject_set: subject_set, user: resource_owner }
    let(:api_user) { ApiUser.new(resource_owner) }
    let(:policy) { SubjectSetImportPolicy.new(api_user, subject_set_import) }

    it 'links to subject sets of projects the user is a collaborator of' do
      create :subject_set # not owned
      expect(policy.linkable_subject_sets).to match_array([subject_set])
    end
  end
end
