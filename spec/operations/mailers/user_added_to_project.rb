require 'spec_helper'

describe Mailers::UserAddedToProject do
  let(:api_user) { ApiUser.new(build_stubbed(:user)) }
  let(:resource) { create(:project) }

  it "calls the mailer worker" do
    expect(UserAddedToProjectMailerWorker).to receive(:perform_async)
    described_class.run!(api_user: api_user, resource_id: resource.id, roles: ["collaborator"])
  end

end
