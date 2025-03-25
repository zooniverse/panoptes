# frozen_string_literal: true

class RevokeTokensWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(application_id_to_revoke, user_id)
    user = User.find(user_id)
    Doorkeeper::AccessToken.revoke_all_for(
      application_id_to_revoke,
      user
    )
  end
end
