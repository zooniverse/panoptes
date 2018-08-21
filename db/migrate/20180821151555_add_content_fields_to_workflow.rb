class AddContentFieldsToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :strings, :jsonb
  end
end
