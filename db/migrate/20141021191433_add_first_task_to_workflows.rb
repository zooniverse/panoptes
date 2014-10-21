class AddFirstTaskToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :first_task, :string
  end
end
