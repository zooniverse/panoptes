require 'spec_helper'

RSpec.describe UserInfoChangedMailerWorker do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:prev_email) { 'oldemaild@example.com' }

  context 'when delivering an email' do
    it 'delivers the mail' do
      expect { subject.perform(user.id, 'password') }.to change { 'ActionMailer::Base'.constantize.deliveries.count }.by(1)
    end

    it 'delivers to the right recipients' do
      subject.perform(user.id, 'email', prev_email)
      mail = 'ActionMailer::Base'.constantize.deliveries.last
      expect(mail.to).to eq([user.email, prev_email])
    end
  end

  context "without a user" do
    it 'should not deliver the mail' do
      expect{ subject.perform(nil, "password") }.to_not change{ 'ActionMailer::Base'.constantize.deliveries.count }
    end
  end

  context "when an the user has been scrubbed of email address" do
    it 'should not deliver the mail' do
      UserInfoScrubber.scrub_personal_info!(user)
      expect{ subject.perform(user.id, "password") }.to_not change{ 'ActionMailer::Base'.constantize.deliveries.count }
    end
  end

  context "when the user has an invalid email" do
    [ Net::SMTPSyntaxError, Net::SMTPFatalError ].each do |error_klass|
      before(:each) do
        allow_any_instance_of(ActionMailer::MessageDelivery)
          .to receive(:deliver)
          .and_raise(error_klass.new('test@example.com,ox'))
        allow(user).to receive("email").and_return("test@example.com,ox")
      end

      it 'should attempt to send an email' do
        expect_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver)
        subject.perform(user.id, "password")
      end

      it 'should mark the user with invalid_email' do
        subject.perform(user.id, "password")
        expect(user.reload.valid_email).to eq(false)
      end
    end
  end
end
