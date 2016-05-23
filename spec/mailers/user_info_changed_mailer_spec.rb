require "spec_helper"

RSpec.describe UserInfoChangedMailer, :type => :mailer do
  let(:user) { create(:user) }
  let(:mail) { UserInfoChangedMailer.user_info_changed(user, :password)}

  describe "#user_info_changed" do

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    context "password was changed" do
      it 'should have the correct subject' do
        expect(mail.subject).to eq("Your Zooniverse password has been changed")
      end
    end

    context "email address was changed" do
      let(:mail) { UserInfoChangedMailer.user_info_changed(user, :email)}
      it 'should have the correct subject' do
        expect(mail.subject).to eq("Your Zooniverse email address has been changed")
      end
    end
  end
end
