require 'spec_helper'
require "zlib"

describe UserInfoScrubber do

  describe '::scrub_personal_info!!' do
    let(:scrub_user_details) { UserInfoScrubber.scrub_personal_info!(user) }

    context "when using an active user" do
      let(:user) { create(:user) }

      it 'should set set their email address to nil' do
        scrub_user_details
        expect(user.email).to eq(UserInfoScrubber::DELETED_USER_EMAIL)
      end

      it "should replace their display name" do
        scrub_user_details
        expect(user.display_name).to eq("deleted_user")
      end

      it "should hash their login" do
        hashed_login_string = Zlib.crc32(user.login).to_s
        scrub_user_details
        expect(user.login).to eq(hashed_login_string)
      end
    end

    context "when using an active user" do
      let(:user) { create(:inactive_user) }

      it 'should not change the persisted instance' do
        scrub_user_details
        expect(user.changed?).to eq(false)
      end

      it 'should return false as the user is already disabled' do
        expect(scrub_user_details).to eq(false)
      end
    end
  end
end
