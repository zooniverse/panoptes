require "spec_helper"

RSpec.describe ProjectRequestEmailWorker do
  let(:project) { create(:project) }

  it 'should send mail' do
    expect do
      subject.perform("beta", project.id)
    end.to change{ ActionMailer::Base.deliveries.count }.by(1)
  end
end
