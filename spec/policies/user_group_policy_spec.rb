require 'spec_helper'

describe UserGroupPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:group_admin) { create(:user) }

    let(:public_user_group) { create(:user_group, admin: group_admin, private: false) }
    let(:private_user_group) { create(:user_group, admin: group_admin, private: true) }

    before do
      public_user_group.save!
      private_user_group.save!
    end

    subject do
      PunditScopeTester.new(UserGroup, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array(public_user_group) }
      its(:show) { is_expected.to match_array(public_user_group) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array(public_user_group) }
      its(:show) { is_expected.to match_array(public_user_group) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as a group member' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :membership, user: logged_in_user, user_group: private_user_group, roles: ['group_member']
      end

      its(:index) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:show) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as the group admin' do
      let(:api_user) { ApiUser.new(group_admin) }

      its(:index) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:show) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:update) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:destroy) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:update_links) { is_expected.to match_array([public_user_group, private_user_group]) }
      its(:destroy_links) { is_expected.to match_array([public_user_group, private_user_group]) }
    end
  end

  describe "links" do
    let(:user) { create :user }
    let(:api_user) { ApiUser.new(user) }
    let(:user_group) { build :user_group }
    let(:policy) { described_class.new(api_user, user_group) }

    it "should allow user_gruop links to any user" do
      expect(policy.linkable_users).to match_array(user)
    end
  end
end
