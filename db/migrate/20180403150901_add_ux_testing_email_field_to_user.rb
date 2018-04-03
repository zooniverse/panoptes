class AddUxTestingEmailFieldToUser < ActiveRecord::Migration
  def change
    add_column :users, :ux_testing_email_communication, :boolean
    User.update_all(ux_testing_email_communication: false)

    reversible do |dir|
      dir.up do
        change_column_default(:users, :ux_testing_email_communication, false)
      end
      dir.down do
        change_column_default(:users, :ux_testing_email_communication, nil)
      end
    end
  end
end
