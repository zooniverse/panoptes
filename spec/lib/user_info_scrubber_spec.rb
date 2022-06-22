require 'spec_helper'

def scrub_user_details(user)(user)
  UserInfoScrubber.scrub_personal_info!(user)
end

describe UserInfoScrubber do
  describe '::scrub_personal_info!', :focus do
    context "when using an active user" do
      let(:user) { create(:user, current_sign_in_ip: '1.2.3.4', last_sign_in_ip: '1.2.3.5', tsv: 'foo', private_profile: false, nasa_email_communication: true) }

      it 'scrubs the email' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :email)
      end

      it 'scrubs the current_sign_in_ip' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :current_sign_in_ip).to(nil)
      end

      it 'scrubs the last_sign_in_ip' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :last_sign_in_ip).to(nil)
      end

      it 'scrubs the display_name' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :display_name).to("Deleted user #{user.id}")
      end

      it 'scrubs the login' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :login).to("deleted-#{user.id}")
      end

      it 'scrubs the credited_name' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :credited_name).to(nil)
      end

      it 'scrubs the encrypted_password' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :encrypted_password)
      end

      it 'scrubs the global_email_communication' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :global_email_communication).to(false)
      end

      it 'scrubs the project_email_communication' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :project_email_communication).to(false)
      end

      it 'scrubs the beta_email_communication' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :beta_email_communication).to(false)
      end

      it 'scrubs the nasa_email_communication' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :nasa_email_communication).to(false)
      end

      it 'scrubs the valid_email' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :valid_email).to(false)
      end

      it 'scrubs the private_profile' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :private_profile).to(true)
      end

      it 'scrubs the api_key' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :api_key).to(nil)
      end

      it 'scrubs the tsv' do
        expect { described_class.scrub_personal_info!(user) }.to change(user, :tsv).to(nil)
      end
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
