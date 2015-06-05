class AddBetaEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :beta_email_communication, :boolean

    add_index :users, :global_email_communication, where: "global_email_communication IS TRUE"
    add_index :users, :beta_email_communication, where: "beta_email_communication IS TRUE"
  end
end
