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
end
