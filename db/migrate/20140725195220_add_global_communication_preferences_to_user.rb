class AddGlobalCommunicationPreferencesToUser < ActiveRecord::Migration
  def change
    add_column :users, :global_email_communication, :boolean
    add_column :users, :project_email_communication, :boolean
  end
end
