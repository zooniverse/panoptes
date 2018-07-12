require 'spec_helper'

describe Doorkeeper::AccessCleanup do
  shared_examples 'it cleans up after doorkeeper' do
    it "should not cleanup non-expired"  do
      cleaner.cleanup!
      expect{ instance.reload }.not_to raise_error
    end

    it "should not cleanup non-revoked" do
      cleaner.cleanup!
      expect{ instance.reload }.not_to raise_error
    end

    it "should cleanup all revoked" do
      instance.revoke
      cleaner.cleanup!
      expect{ instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should cleanup all expired" do
      instance.update_column(:created_at, Time.now - (expires_in + 60).seconds)
      cleaner.cleanup!
      expect{ instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'cleanup!' do
    let(:cleaner) { described_class.new }
    let(:owner) { create(:user) }
    let(:app) { create(:application, owner: owner)}
    let(:expires_in) { 7200 }
    let(:scopes) { "public test" }

    describe "tokens" do
      let(:instance) do
        create(:access_token,
          scopes: scopes,
          resource_owner_id: owner.id,
          application_id: app.id,
          expires_in: expires_in,
          use_refresh_token: true)
      end

      it "should cleanup an expired refreshable token that has not been refreshed" do
        instance.update_column(:created_at, Time.now - 14.days)
        cleaner.cleanup!
        expect{ instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it_should_behave_like "it cleans up after doorkeeper" do
        let!(:instance) do
          create(:access_token,
            scopes: scopes,
            resource_owner_id: owner.id,
            application_id: app.id,
            expires_in: expires_in)
        end
      end
    end

    describe "grants" do
      let!(:instance) do
        create(:access_grant,
          resource_owner_id: owner.id,
          application_id: app.id,
          redirect_uri: 'urn:ietf:wg:oauth:2.0:oob',
          expires_in: expires_in,
          scopes: scopes)
      end

      it_should_behave_like "it cleans up after doorkeeper"
    end
  end
end
