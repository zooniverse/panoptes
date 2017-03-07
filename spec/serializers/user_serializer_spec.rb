require "spec_helper"

RSpec.describe UserSerializer do
  let(:sign_in) { 1 }
  let(:migrated) { false }
  let(:user) { create(:user, migrated: migrated, sign_in_count: sign_in) }
  let(:context) { {} }

  let(:serializer) do
    described_class.new.tap do |serializer|
      serializer.instance_variable_set(:@model, user)
      serializer.instance_variable_set(:@context, context)
    end
  end

  describe "#login_prompt" do
    let(:context) { {requesting_user: user} }

    subject do
      serializer.login_prompt
    end

    context "a migrated user" do
      let(:migrated) { true }
      context "with a previous sign on" do
        let(:sign_in) { 2 }

        it { is_expected.to be false }
      end

      context "without a previous sign on" do
        let(:sign_in) { 1 }

        it { is_expected.to be true }
      end
    end

    context "a non-migrated-user" do
      let(:migrated) { false }
      let(:sign_in) { 10 }

      it { is_expected.to be false }
    end
  end

  describe '#avatar_src' do
    it 'returns nil if avatar is not loaded' do
      expect(serializer.avatar_src).to eq(nil)
    end

    it 'returns nil if user does not have an avatar' do
      user.avatar = nil
      expect(serializer.avatar_src).to eq(nil)
    end

    it 'returns a src if user has an avatar and loaded' do
      avatar = build(:medium, type: "user_avatar", linked: user)
      user.avatar = avatar
      user.save!
      expect(serializer.avatar_src).to eq(avatar.url_for_format(:get))
    end
  end
end
