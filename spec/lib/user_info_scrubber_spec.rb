require 'spec_helper'

def scrub_user_details(user)(user)
  UserInfoScrubber.scrub_personal_info!(user)
end

describe UserInfoScrubber do

  describe '::scrub_personal_info!' do

    context "when using an active user" do
      let(:user) { create(:user) }

      it 'should set set their email address to nil' do
        scrub_user_details(user)
        expect(user.email).to be_nil
      end

      it "should not replace their display name" do
        prev_user_login = user.login
        scrub_user_details(user)
        expect(user.login).to eq(prev_user_login)
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
