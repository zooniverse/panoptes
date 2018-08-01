require 'spec_helper'

describe TutorialPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_tutorial) { build(:tutorial, project: public_project) }
    let(:private_tutorial) { build(:tutorial, project: private_project) }

    subject do
      PunditScopeTester.new(Tutorial, api_user)
    end

    before do
      public_tutorial.save!
      private_tutorial.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([public_tutorial]) }
      its(:show) { is_expected.to match_array([public_tutorial]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([public_tutorial]) }
      its(:show) { is_expected.to match_array([public_tutorial]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([public_tutorial, private_tutorial]) }
      its(:show) { is_expected.to match_array([public_tutorial, private_tutorial]) }
      its(:update) { is_expected.to match_array([private_tutorial]) }
      its(:destroy) { is_expected.to match_array([private_tutorial]) }
      its(:translate) { is_expected.to match_array([private_tutorial]) }
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

      its(:index) { is_expected.to match_array([public_tutorial, private_tutorial]) }
      its(:show) { is_expected.to match_array([public_tutorial, private_tutorial]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to match_array([private_tutorial]) }
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }
      let(:all_tutorials) do
        [public_tutorial, private_tutorial]
      end

      its(:index) { is_expected.to match_array(all_tutorials) }
      its(:show) { is_expected.to match_array(all_tutorials) }
      its(:update) { is_expected.to match_array(all_tutorials) }
      its(:destroy) { is_expected.to match_array(all_tutorials) }
      its(:translate) { is_expected.to match_array(all_tutorials) }
    end
  end
end
