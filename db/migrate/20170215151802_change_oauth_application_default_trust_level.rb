class ChangeOauthApplicationDefaultTrustLevel < ActiveRecord::Migration
  def change
    Doorkeeper::Application.where(trust_level: 0).update_all(trust_level: 1)
    change_column_default(:oauth_applications, :trust_level, 1)
  end
end
