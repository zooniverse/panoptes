require 'spec_helper'

describe SubjectPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_subject) { build(:subject, project: public_project) }
    let(:private_subject) { build(:subject, project: private_project) }

    subject do
      PunditScopeTester.new(Subject, api_user)
    end

    before do
      public_subject.save!
      private_subject.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([public_subject]) }
      its(:show) { is_expected.to match_array([public_subject]) }
      its(:adjacent) { is_expected.to match_array([public_subject]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:version) { is_expected.to match_array([public_subject]) }
      its(:versions) { is_expected.to match_array([public_subject]) }
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([public_subject]) }
      its(:show) { is_expected.to match_array([public_subject]) }
      its(:adjacent) { is_expected.to match_array([public_subject]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:version) { is_expected.to match_array([public_subject]) }
      its(:versions) { is_expected.to match_array([public_subject]) }
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([public_subject, private_subject]) }
      its(:show) { is_expected.to match_array([public_subject, private_subject]) }
      its(:adjacent) { is_expected.to match_array([public_subject, private_subject]) }
      its(:update) { is_expected.to match_array([private_subject]) }
      its(:destroy) { is_expected.to match_array([private_subject]) }
      its(:version) { is_expected.to match_array([public_subject, private_subject]) }
      its(:versions) { is_expected.to match_array([public_subject, private_subject]) }
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }
      let(:all_subjects) do
        [public_subject, private_subject]
      end

      its(:index) { is_expected.to match_array(all_subjects) }
      its(:show) { is_expected.to match_array(all_subjects) }
      its(:adjacent) { is_expected.to match_array(all_subjects) }
      its(:update) { is_expected.to match_array(all_subjects) }
      its(:destroy) { is_expected.to match_array(all_subjects) }
      its(:version) { is_expected.to match_array(all_subjects) }
      its(:versions) { is_expected.to match_array(all_subjects) }
    end
  end
end
