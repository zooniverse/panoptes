require 'spec_helper'

describe UserPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:ouroboros_user) do
      User.skip_callback :validation, :before, :update_ouroboros_created
      u = build(:user, activated_state: 0, ouroboros_created: true, build_group: false)
      u.save(validate: false)
      User.set_callback :validation, :before, :update_ouroboros_created
      u
    end

    let(:other_user) { build(:user) }

    before do
      other_user.save!
      ouroboros_user
    end

    subject do
      PunditScopeTester.new(User, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([logged_in_user, other_user]) }
      its(:show) { is_expected.to match_array([logged_in_user, other_user]) }
      its(:update) { is_expected.to be_empty }
      its(:deactivate) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([logged_in_user, other_user]) }
      its(:show) { is_expected.to match_array([logged_in_user, other_user]) }
      its(:update) { is_expected.to match_array([logged_in_user]) }
      its(:deactivate) { is_expected.to match_array([logged_in_user]) }
      its(:destroy) { is_expected.to match_array([logged_in_user]) }
    end

    context 'as a admin user' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      its(:index) { is_expected.to match_array([admin_user, ouroboros_user, logged_in_user, other_user]) }
      its(:show) { is_expected.to match_array([admin_user, ouroboros_user, logged_in_user, other_user]) }
      its(:update) { is_expected.to match_array([admin_user, ouroboros_user, logged_in_user, other_user]) }
      its(:deactivate) { is_expected.to match_array([admin_user, ouroboros_user, logged_in_user, other_user]) }
      its(:destroy) { is_expected.to match_array([admin_user, ouroboros_user, logged_in_user, other_user]) }
    end
  end
end
