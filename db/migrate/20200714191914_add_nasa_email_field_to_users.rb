class AddNasaEmailFieldToUsers < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_column :users, :nasa_email_communication, :boolean
    change_column_default :users, :nasa_email_communication, false
    add_index :users, :nasa_email_communication, where: "nasa_email_communication = true", algorithm: :concurrently
  end
end
