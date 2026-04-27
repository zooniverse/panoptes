class DropAuthorizationsTable < ActiveRecord::Migration[6.1]
  def change
    drop_table :authorizations, if_exists: true
  end
end
