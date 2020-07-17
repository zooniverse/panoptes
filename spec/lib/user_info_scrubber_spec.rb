require 'spec_helper'

def scrub_user_details(user)(user)
  UserInfoScrubber.scrub_personal_info!(user)
end

describe UserInfoScrubber do
  describe '::scrub_personal_info!' do
    context "when using an active user" do
      let(:user) { create(:user, current_sign_in_ip: '1.2.3.4', last_sign_in_ip: '1.2.3.5', tsv: 'foo', private_profile: false, nasa_email_communication: true) }

      subject(:changes) do
        -> { described_class.scrub_personal_info!(user) }
      end

      it { is_expected.to change(user, :email) }
      it { is_expected.to change(user, :current_sign_in_ip).to(nil) }
      it { is_expected.to change(user, :last_sign_in_ip).to(nil) }
      it { is_expected.to change(user, :display_name).to("Deleted user #{user.id}") }
      it { is_expected.to change(user, :login).to("deleted-#{user.id}") }
      it { is_expected.to change(user, :credited_name).to(nil) }
      it { is_expected.to change(user, :encrypted_password) }
      it { is_expected.to change(user, :global_email_communication).to(false) }
      it { is_expected.to change(user, :project_email_communication).to(false) }
      it { is_expected.to change(user, :beta_email_communication).to(false) }
      it { is_expected.to change(user, :nasa_email_communication).to(false) }
      it { is_expected.to change(user, :valid_email).to(false) }
      it { is_expected.to change(user, :private_profile).to(true) }
      it { is_expected.to change(user, :api_key).to(nil) }
      it { is_expected.to change(user, :tsv).to(nil) }
    end

    context "when a previous user has been deleted" do
      let!(:setup_deleted_user) do
        user = create(:user)
        scrub_user_details(user)
      end
      let(:user) { create(:user) }

      it "should not raise an error scrubbing the second user" do
        expect{ scrub_user_details(user) }.to_not raise_error
      end
    end

    context "when using an inactive user" do
      let(:user) { create(:inactive_user) }

      it 'should raise an error as the user is already disabled' do
        error_message = "Can't scrub personal details of a disabled user with id: #{user.id}"
        expect { scrub_user_details(user) }.to raise_error(UserInfoScrubber::ScrubDisabledUserError, error_message)
      end

      it 'should not change the persisted instance' do
        scrub_user_details(user) rescue nil
        expect(user.changed?).to eq(false)
      end
    end
  end
end
