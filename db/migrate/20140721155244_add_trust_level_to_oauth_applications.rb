class AddTrustLevelToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :trust_level, :integer, default: 0, null: false
  end
end
