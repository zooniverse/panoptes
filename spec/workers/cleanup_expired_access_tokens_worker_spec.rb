require 'spec_helper'

describe CleanupExpiredAccessTokensWorker do
  let(:worker) { described_class.new }
  let(:user) { create(:user) }
  let(:access_token) { create(:access_token, resource_owner_id: user.id) }
  let(:access_grant) { create(:access_grant, resource_owner_id: user.id) }

  it{ is_expected.to be_a Sidekiq::Worker }

  describe 'schedule' do
    it "should have a valid schedule" do
      expect(described_class.schedule.to_s).to match(/Daily/)
    end
  end

  describe "perform" do
    before do
      access_token
    end

    def make_old(resource)
      resource.update_column(:created_at, resource.created_at - 31.days)
    end

    it 'should not cleanup valid tokens' do
      worker.perform
      expect { access_token.reload }.not_to raise_error
    end

    it 'should not cleanup valid access grant' do
      worker.perform
      expect { access_token.reload }.not_to raise_error
    end

    it "should cleanup revoked tokens" do
      access_token.revoke
      worker.perform
      expect { access_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should cleanup old tokens" do
      make_old(access_token)
      worker.perform
      expect { access_token.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should cleanup the revoked access grants" do
      access_grant.revoke
      worker.perform
      expect { access_grant.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should cleanup the old access grants" do
      make_old(access_grant)
      worker.perform
      expect { access_grant.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
