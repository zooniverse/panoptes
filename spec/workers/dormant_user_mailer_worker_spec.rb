require 'spec_helper'

RSpec.describe DormantUserMailerWorker do
  let(:user) { create(:user) }

  it 'should deliver the mail' do
    expect{ subject.perform(user.id) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

  context "when the user has an invalid email" do
    [ Net::SMTPSyntaxError, Net::SMTPFatalError ].each do |error_klass|
      before do
        allow_any_instance_of(ActionMailer::MessageDelivery)
        .to receive(:deliver)
        .and_raise(error_klass.new)
      end

      it 'should attempt to send an email' do
        mail_message_double = instance_double("Mail::Message")
        expect(mail_message_double).to receive(:deliver)
        allow(DormantUserMailer)
          .to receive(:email_dormant_user)
          .and_return(mail_message_double)
        subject.perform(user.id)
      end

      it 'should mark the user with invalid_email' do
        expect {
          subject.perform(user.id)
        }.to change {
          user.reload.valid_email
        }.from(true).to(false)
      end
    end
  end
end
