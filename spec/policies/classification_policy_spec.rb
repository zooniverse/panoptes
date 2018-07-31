require 'spec_helper'

describe ClassificationPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }
    let(:resource_owner) { create(:user) }

    let(:keep_data_in_panoptes_only_project) { create :project, configuration: {"keep_data_in_panoptes_only" => true} }
    let(:project) { create :project, owner: resource_owner }

    let(:keep_data_in_panoptes_only_classification) { build :classification, project: keep_data_in_panoptes_only_project }
    let(:incomplete_classification) { build(:classification, project: project, completed: false, user: logged_in_user) }
    let(:classification) { build(:classification, project: project, user: logged_in_user) }

    before do
      keep_data_in_panoptes_only_classification.save!
      incomplete_classification.save!
      classification.save!
    end

    subject do
      PunditScopeTester.new(Classification, api_user)
    end

    context 'as an anonymous user' do
      let(:api_user) { ApiUser.new(anonymous_user) }

      its(:index) { is_expected.to be_empty }
      its(:show) { is_expected.to be_empty }
      its(:project) { is_expected.to be_empty }
      its(:incomplete) { is_expected.to be_empty }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
    end

    context 'as a normal user' do
      let(:api_user) { ApiUser.new(logged_in_user) }

      its(:index) { is_expected.to match_array([classification]) }
      its(:show) { is_expected.to match_array([classification, incomplete_classification]) }
      its(:project) { is_expected.to be_empty }
      its(:incomplete) { is_expected.to match_array([incomplete_classification]) }
      its(:update) { is_expected.to match_array([incomplete_classification]) }
      its(:destroy) { is_expected.to match_array([incomplete_classification]) }
    end

    context 'as the project owner or collaborator', :focus do
      let(:api_user) { ApiUser.new(resource_owner) }

      its(:index) { is_expected.to be_empty }
      its(:show) { is_expected.to be_empty }
      its(:project) { is_expected.to match_array([classification, incomplete_classification]) }
      its(:incomplete) { is_expected.to be_empty }
      its(:update) { is_expected.to be_empty }
      its(:destroy) { is_expected.to be_empty }
    end

    context 'as an admin' do
      let(:admin_user) { create :user, admin: true }
      let(:api_user) { ApiUser.new(admin_user, admin: true) }

      its(:index) { is_expected.to match_array([classification]) }
      its(:show) { is_expected.to match_array([classification, incomplete_classification]) }
      its(:project) { is_expected.to match_array([classification, incomplete_classification]) }
      its(:incomplete) { is_expected.to match_array([incomplete_classification]) }
      its(:update) { is_expected.to match_array([incomplete_classification]) }
      its(:destroy) { is_expected.to match_array([incomplete_classification]) }
    end
  end
end
