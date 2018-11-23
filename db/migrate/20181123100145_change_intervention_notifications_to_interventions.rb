class ChangeInterventionNotificationsToInterventions < ActiveRecord::Migration
  def change
    rename_column :users, :intervention_notifications, :interventions
  end
end
