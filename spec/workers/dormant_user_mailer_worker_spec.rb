require 'spec_helper'

RSpec.describe DormantUserMailerWorker do
  let(:user) { create(:user) }

  it 'should deliver the mail' do
    expect{ subject.perform(user.id) }.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end

end
