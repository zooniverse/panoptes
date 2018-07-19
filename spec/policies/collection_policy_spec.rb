require 'spec_helper'

describe CollectionPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:public_collection) { build(:collection, owner: resource_owner) }
    let(:private_collection) { build(:private_collection, owner: resource_owner) }

    before do
      public_collection.save!
      private_collection.save!
    end

    subject do
      PunditScopeTester.new(Collection, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to match_array(public_collection) }
      its(:show) { is_expected.to match_array(public_collection) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array(public_collection) }
      its(:show) { is_expected.to match_array(public_collection) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as a viewer' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_collection, roles: ['viewer']
      end

      its(:index) { is_expected.to match_array([public_collection, private_collection]) }
      its(:show) { is_expected.to match_array([public_collection, private_collection]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to be_empty }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as a contributor' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_collection, roles: ['contributor']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_collection, roles: ['contributor']
      end

      its(:index) { is_expected.to match_array([public_collection, private_collection]) }
      its(:show) { is_expected.to match_array([public_collection, private_collection]) }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
      its(:update_links) { is_expected.to match_array([public_collection, private_collection]) }
      its(:destroy_links) { is_expected.to be_empty }
    end

    context 'as a collaborator' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      before do
        create :access_control_list, user_group: logged_in_user.identity_group, resource: public_collection, roles: ['collaborator']
        create :access_control_list, user_group: logged_in_user.identity_group, resource: private_collection, roles: ['collaborator']
      end

      its(:index) { is_expected.to match_array([public_collection, private_collection]) }
      its(:show) { is_expected.to match_array([public_collection, private_collection]) }
      its(:update) { is_expected.to match_array([public_collection, private_collection]) }
      its(:destroy) { is_expected.to match_array([public_collection, private_collection]) }
      its(:update_links) { is_expected.to match_array([public_collection, private_collection]) }
      its(:destroy_links) { is_expected.to match_array([public_collection, private_collection]) }
    end

    context 'as the owner' do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to match_array([public_collection, private_collection]) }
      its(:show) { is_expected.to match_array([public_collection, private_collection]) }
      its(:update) { is_expected.to match_array([public_collection, private_collection]) }
      its(:destroy) { is_expected.to match_array([public_collection, private_collection]) }
      its(:update_links) { is_expected.to match_array([public_collection, private_collection]) }
      its(:destroy_links) { is_expected.to match_array([public_collection, private_collection]) }
    end
  end
end
