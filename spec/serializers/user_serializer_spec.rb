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
    let(:result) do
      described_class.page({}, User.where(id: user.id), context)
    end

    it 'returns nil if user does not have an avatar' do
      user.avatar = nil
      user.save!
      expect(result[:users][0][:avatar_src]).to eq(nil)
    end

    it 'returns a src if user has an avatar' do
      avatar = build(:medium, type: "user_avatar", linked: user)
      user.avatar = avatar
      user.save!
      expect(result[:users][0][:avatar_src]).to eq(avatar.url_for_format(:get))
    end
  end

  describe "a confused user" do
    let!(:confused_user) { create(:user, credited_name: "oops@email.com", login: "confused_user" )}
    let(:confused_serializer) { described_class.serialize(confused_user) }

    it "serialized the user's login as credited_name if credited_name contains an @" do
      expect(confused_serializer[:users][0][:credited_name]).to eq("confused_user")
    end
  end
end
