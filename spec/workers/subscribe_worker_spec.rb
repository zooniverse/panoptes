require 'spec_helper'

RSpec.describe SubscribeWorker do
  let(:user) { create(:user) }

  it 'should send mail' do
    expect do
      subject.perform(user.email, user.display_name)
    end.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end
end
