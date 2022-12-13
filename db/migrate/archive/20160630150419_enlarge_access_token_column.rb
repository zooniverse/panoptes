class EnlargeAccessTokenColumn < ActiveRecord::Migration
  def change
    change_column :oauth_access_tokens, :token, :text
  end
end
