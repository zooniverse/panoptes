require 'spec_helper'

describe GetDormantUsersWorker do
  let(:worker) { described_class.new }

  it "should email dormant users in subselection" do
    dormant_user1 = create(:user, id: 45, current_sign_in_at: 5.days.ago)
    dormant_user2 = create(:user, id: 5, current_sign_in_at: 5.days.ago)

    expect(DormantUserMailerWorker).to receive(:perform_async).with(dormant_user1.id)
    expect(DormantUserMailerWorker).to receive(:perform_async).with(dormant_user2.id)

    worker.perform(5, 5)
  end
end
