# frozen_string_literal: true

require 'spec_helper'

describe SubjectGroupPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project, owner: resource_owner) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_subject_group) { build(:subject_group, project: public_project) }
    let(:private_subject_group) { build(:subject_group, project: private_project) }

    let(:resolved_scope) do
      Pundit.policy!(api_user, SubjectGroup).scope_for(:index)
    end

    before do
      public_subject_group.save!
      private_subject_group.save!
    end

    context 'with an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      it 'includes subject_groups from public projects' do
        expect(resolved_scope).to match_array(public_subject_group)
      end
    end

    context 'with a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      it 'includes public_subject_groups from public projects' do
        expect(resolved_scope).to match_array(public_subject_group)
      end
    end

    context 'with the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      it 'includes public_subject_groups from public projects' do
        expect(resolved_scope).to include(public_subject_group)
      end

      it 'includes public_subject_groups from owned private projects' do
        expect(resolved_scope).to include(private_subject_group)
      end
    end

    context 'with an admin user' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      it 'includes everything' do
        expect(resolved_scope).to include(public_subject_group, private_subject_group)
      end
    end
  end
end
