class AddContentFieldsToWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :strings, :jsonb

    reversible do |dir|
      dir.up do
        change_column_default :workflows, :strings, {}
      end
    end
  end
end
