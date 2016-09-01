require 'spec_helper'

describe Doorkeeper::AccessCleanup do

  shared_examples 'it cleans up after doorkeeper' do

    it "should not cleanup expired" do
      cleaner.cleanup!
      expect{ instance.reload }.not_to raise_error
    end

    it "should not cleanup revoked" do
      cleaner.cleanup!
      expect{ instance.reload }.not_to raise_error
    end

    it "should cleanup a revoked" do
      instance.revoke
      cleaner.cleanup!
      expect{ instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "should cleanup an old expired" do
      instance.update_column(:created_at, DateTime.now - 31.day)
      cleaner.cleanup!
      expect{ instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'cleanup!' do
    let(:cleaner) { described_class.new }
    let(:owner) { create(:user) }
    let(:app) { create(:application, owner: owner)}

    it_should_behave_like "it cleans up after doorkeeper" do
      let!(:instance) do
        Doorkeeper::AccessToken.create! do |ac|
          ac.resource_owner_id = owner.id
          ac.application_id = app.id
          ac.expires_in = 7200
          ac.scopes = "public test"
        end
      end
    end

    it_should_behave_like "it cleans up after doorkeeper" do
      let!(:instance) do
        Doorkeeper::AccessGrant.create! do |ag|
          ag.resource_owner_id = owner.id
          ag.application_id = app.id
          ag.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
          ag.expires_in = 7200
          ag.scopes = "public test"
        end
      end
    end
  end
end
