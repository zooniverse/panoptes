class AddUserInterventionNotifications < ActiveRecord::Migration
  def change
    add_column :users, :intervention_notifications, :boolean

    reversible do |dir|
      dir.up do
        change_column_default(:users, :intervention_notifications, true)
      end
    end
  end
end
