require 'spec_helper'

describe Devise::BackgroundMailer, sidekiq: :inline do
  let(:user) { create(:user) }
  let(:mailer) do
    Devise::BackgroundMailer.reset_password_instructions(user, "token")
  end

  before do
    allow_any_instance_of(User).to receive(:send_welcome_email)
  end

  it "should send an email" do
    expect {
      mailer.deliver
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  context "when redis is down" do
    it "should send an email normally" do
      [ Redis::CannotConnectError, Redis::TimeoutError, Timeout::Error ].each do |redis_error|
        allow(Devise::Mailer).to receive(:delay).and_raise(redis_error)
        expect {
          mailer.deliver
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
