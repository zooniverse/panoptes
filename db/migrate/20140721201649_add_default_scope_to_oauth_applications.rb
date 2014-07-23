class AddDefaultScopeToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :default_scope, :string, array: true, default: '{}'
  end
end
