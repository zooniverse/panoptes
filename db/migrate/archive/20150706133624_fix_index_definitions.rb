class FixIndexDefinitions < ActiveRecord::Migration
  def change
    remove_index :projects, column: :beta_requested
    remove_index :projects, column: :launch_requested

    remove_index :users, column: :global_email_communication
    remove_index :users, column: :beta_email_communication
    remove_index :users, column: :ouroboros_created

    add_index :projects, :beta_requested, where: "beta_requested = true"
    add_index :projects, :launch_requested, where: "launch_requested = true"

    add_index :users, :global_email_communication, where: "global_email_communication = true"
    add_index :users, :beta_email_communication, where: "beta_email_communication = true"
    add_index :users, :ouroboros_created, where: "ouroboros_created = false"
  end
end
