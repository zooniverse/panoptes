require 'spec_helper'

RSpec.describe UnsubscribeWorker do
  let(:user) { create(:user) }
  it 'should send mail' do
    expect{ subject.perform(user.email) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end
end
