require "spec_helper"

RSpec.describe UserSerializer do
  let(:user) { create(:user, migrated: migrated, sign_in_count: sign_in) }

  describe "#login_prompt" do
    subject do
      s =described_class.new
      s.instance_variable_set(:@model, user)
      s.instance_variable_set(:@context, {requesting_user: user})
      s.login_prompt
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
end
