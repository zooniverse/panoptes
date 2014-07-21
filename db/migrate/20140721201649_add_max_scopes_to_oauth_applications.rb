class AddMaxScopesToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :max_scope, :string, array: true, default: '{}'
  end
end
