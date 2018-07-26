require 'spec_helper'

describe UserProjectPreferencePolicy do
  describe 'scopes' do
    let(:user) { create(:user) }

    let(:private_project) { build :project, private: true }

    let(:public_preference) { build(:user_project_preference, user: user, public: true) }
    let(:private_preference) { build(:user_project_preference, user: user) }
    let(:other_user_public_preference) { build(:user_project_preference, public: true) }
    let(:other_user_private_preference) { build(:user_project_preference) }
    let(:private_project_public_preference) { build(:user_project_preference, public: true, project: private_project) }

    before do
      public_preference.save!
      private_preference.save!
      other_user_public_preference.save!
      other_user_private_preference.save!
      private_project_public_preference.save!
    end

    subject do
      PunditScopeTester.new(UserProjectPreference, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(nil) }

      its(:index) { is_expected.to be_empty }
      its(:show) { is_expected.to be_empty }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(user) }

      its(:index) { is_expected.to match_array([public_preference, private_preference]) }
      its(:show) { is_expected.to match_array([public_preference, private_preference]) }
      its(:update) { is_expected.to match_array([public_preference, private_preference]) }
      its(:destroy) { is_expected.to match_array([public_preference, private_preference]) }
    end

    context 'as an admin' do
      let(:admin_user) { create(:user, admin: true) }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      its(:index) { is_expected.to match_array([public_preference, private_preference,
                                                other_user_public_preference, other_user_private_preference,
                                                private_project_public_preference]) }
      its(:show) { is_expected.to match_array([public_preference, private_preference,
                                               other_user_public_preference, other_user_private_preference,
                                               private_project_public_preference]) }
      its(:update) { is_expected.to match_array([public_preference, private_preference,
                                                 other_user_public_preference, other_user_private_preference,
                                                 private_project_public_preference]) }
      its(:destroy) { is_expected.to match_array([public_preference, private_preference,
                                                  other_user_public_preference, other_user_private_preference,
                                                  private_project_public_preference]) }
    end
  end
end
