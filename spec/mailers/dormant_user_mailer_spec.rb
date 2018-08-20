require "spec_helper"

RSpec.describe DormantUserMailer, :type => :mailer do
  let(:user) { create(:user) }
  let(:mail) { DormantUserMailer.dormant_user(user)}

  describe "#dormant_user_email" do

    it 'should mail the user' do
      expect(mail.to).to include(user.email)
    end

    it 'should come from no-reply@zooniverse.org' do
      expect(mail.from).to include('no-reply@zooniverse.org')
    end

    it 'should have the correct subject' do
      expect(mail.subject).to eq("Come back to the Zooniverse")
    end

    it 'should have the user name in the body' do
      expect(mail.body.encoded).to match("#{user.display_name}")
    end

  end
end
