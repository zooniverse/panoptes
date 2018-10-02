class WorkflowVersionNumbers < ActiveRecord::Migration
  def change
    add_column :workflows, :major_version, :integer
    add_column :workflows, :minor_version, :integer

    reversible do |dir|
      dir.up do
        change_column_default :workflows, :major_version, 0
        change_column_default :workflows, :minor_version, 0
      end
    end

    Workflow.update_all major_version: 0, minor_version: 0

    reversible do |dir|
      dir.up do
        change_column_null :workflows, :major_version, false
        change_column_null :workflows, :minor_version, false
      end
    end
  end
end
