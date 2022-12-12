class AddFinishedAtToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :finished_at, :datetime
  end
end
