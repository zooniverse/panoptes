require 'spec_helper'

describe FieldGuidePolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_project)  { build(:project) }
    let(:private_project) { build(:project, owner: resource_owner, private: true) }

    let(:public_field_guide) { build(:field_guide, project: public_project) }
    let(:private_field_guide) { build(:field_guide, project: private_project) }

    subject do
      PunditScopeTester.new(FieldGuide, api_user)
    end

    before do
      public_field_guide.save!
      private_field_guide.save!
    end

    context 'for an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array([public_field_guide]) }
      its(:show) { is_expected.to match_array([public_field_guide]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'for a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([public_field_guide]) }
      its(:show) { is_expected.to match_array([public_field_guide]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to be_empty }
    end

    context 'for the resource owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([private_field_guide, public_field_guide]) }
      its(:show) { is_expected.to match_array([private_field_guide, public_field_guide]) }
      its(:update) { is_expected.to match_array([private_field_guide]) }
      its(:destroy) { is_expected.to match_array([private_field_guide]) }
      its(:translate) { is_expected.to match_array([private_field_guide]) }
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

      its(:index) { is_expected.to match_array([private_field_guide, public_field_guide]) }
      its(:show) { is_expected.to match_array([private_field_guide, public_field_guide]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:translate) { is_expected.to match_array([private_field_guide]) }
    end

    context 'for an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }
      let(:all_field_guides) do
        [private_field_guide, public_field_guide]
      end

      its(:index) { is_expected.to match_array(all_field_guides) }
      its(:show) { is_expected.to match_array(all_field_guides) }
      its(:update) { is_expected.to match_array(all_field_guides) }
      its(:destroy) { is_expected.to match_array(all_field_guides) }
      its(:translate) { is_expected.to match_array(all_field_guides) }
    end
  end
end
