class CreateAuthorizations < ActiveRecord::Migration
  def change
    create_table :authorizations do |t|
      t.references :user, index: true
      t.string :provider
      t.string :uid
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
