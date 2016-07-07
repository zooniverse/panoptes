require 'spec_helper'

describe Mailers::UserInfoChanged do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:resource) { create(:project) }

  it "calls the mailer worker" do
    expect(UserInfoChangedMailerWorker).to receive(:perform_async)
    described_class.run!(api_user: api_user, changed: "email")
  end

end
