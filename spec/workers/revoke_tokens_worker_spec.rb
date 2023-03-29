# frozen_string_literal: true

require 'spec_helper'

describe RevokeTokensWorker do
  let(:worker) { described_class.new }
  let(:user) { create(:user) }
  let(:oauth_app) { create(:non_confidential_first_party_app, owner: user) }
  let(:user_token) { create(:access_token, application_id: oauth_app.id, resource_owner_id: user.id) }
  let(:user_other_token) { create(:access_token, application_id: oauth_app.id, resource_owner_id: user.id) }
  let(:user_revoked_token) { create(:access_token, application_id: oauth_app.id, resource_owner_id: user.id) }
  let(:another_user) { create(:user) }
  let(:other_user_token) { create(:access_token, application_id: oauth_app.id, resource_owner_id: another_user.id) }
  let(:other_oauth_app) { create(:non_confidential_first_party_app, owner: user) }
  let(:other_app_token) { create(:access_token, application_id: other_oauth_app.id, resource_owner_id: user.id) }

  before do
    user_token
    user_other_token
    user_revoked_token.revoke
    other_user_token
    other_app_token
  end

  it { is_expected.to be_a Sidekiq::Worker }

  describe 'perform' do
    it 'revokes all access tokens for the relevant client app' do
      expect {
        worker.perform(oauth_app.id, user.id)
      }.to change {
        Doorkeeper::AccessToken.where(application_id: oauth_app.id, resource_owner_id: user.id, revoked_at: nil).count
      }.from(2).to(0)
    end

    it 'does not revoke access token for another user' do
      expect {
        worker.perform(oauth_app.id, user.id)
      }.not_to change {
        Doorkeeper::AccessToken.where(application_id: oauth_app.id, resource_owner_id: another_user.id, revoked_at: nil).count
      }
    end

    it 'does not revoke access token for other client apps' do
      expect {
        worker.perform(oauth_app.id, user.id)
      }.not_to change {
        Doorkeeper::AccessToken.where(application_id: other_oauth_app.id, resource_owner_id: user.id, revoked_at: nil).count
      }
    end
  end
end
