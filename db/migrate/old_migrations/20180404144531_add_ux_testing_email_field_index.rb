class AddUxTestingEmailFieldIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :users, :ux_testing_email_communication,
      where: "(ux_testing_email_communication IS TRUE)",
      algorithm: :concurrently
  end
end
