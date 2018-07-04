require 'spec_helper'

describe CollectionPolicy do
  describe 'scopes' do
    let(:anonymous_user) { nil }
    let(:logged_in_user) { create(:user) }

    let(:other_user) { build(:user) }

    before do
      other_user.save!
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
      its(:update) { is_expected.to eq([logged_in_user]) }
      its(:deactivate) { is_expected.to eq([logged_in_user]) }
      its(:destroy) { is_expected.to eq([logged_in_user]) }
    end
  end
end
