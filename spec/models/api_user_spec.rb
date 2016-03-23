require 'spec_helper'

RSpec.describe ApiUser do
  let(:admin) { false }
  let(:admin_flag) { false }
  let(:user) { create(:user, admin: admin) }

  subject { ApiUser.new(user, admin: admin_flag) }

  describe '#is_admin?' do
    context 'when user is an admin but the flag is not set' do
      let(:admin) { true }

      it { expect(subject.is_admin?).to be false }
    end

    context 'when user is not an admin but the flag is set' do
      let(:admin_flag) { true }

      it { expect(subject.is_admin?).to be false }
    end

    context 'when the user is an admin and the flag is set' do
      let(:admin) { true }
      let(:admin_flag) { true }

      it { expect(subject.is_admin?).to be true }
    end

    context 'when the user is not an admin and the flag is not set' do
      it { expect(subject.is_admin?).to be false }
    end

    context 'when the user is not logged in' do
      let(:user) { nil }

      it { expect(subject.is_admin?).to be false }
    end
  end

  describe "above_subject_limit?" do
    let(:api_user) { ApiUser.new(user, admin: flag) }
    let(:flag) { false }
    let(:user) { create(:user, subject_limit: limit) }

    before(:each) do
      allow_any_instance_of(User).to receive(:uploaded_subjects_count).and_return(10)
    end

    subject { api_user.above_subject_limit? }

    context "user is above limit" do
      let(:limit) { 9 }

      it { is_expected.to be true }
    end

    context "user is below limit" do
      let(:limit) { 11 }

      it { is_expected.to be false }
    end

    context "user is admin" do
      let(:flag) { true }
      let(:user) { create(:user, admin: true) }

      it { is_expected.to be false }
    end

    context "user is whitelisted for upload" do
      before do
        allow_any_instance_of(User).to receive(:upload_whitelist).and_return(true)
      end

      context "user is above limit" do
        let(:limit) { 9 }

        it { is_expected.to be false }
      end

      context "user is below limit" do
        let(:limit) { 11 }

        it { is_expected.to be false }
      end
    end
  end

  describe "subject_limits" do
    let(:api_user) { ApiUser.new(create(:user), admin: false) }

    it "should call the update method and return defaults" do
      aggregate_failures "limits" do
        expect(api_user.subject_limits).to match_array([ 0, Panoptes.max_subjects])
      end
    end
  end
end
