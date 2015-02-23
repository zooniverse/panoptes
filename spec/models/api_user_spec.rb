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
end
