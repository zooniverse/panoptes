class AddRetirementReason < ActiveRecord::Migration
  def change
    add_column :subject_workflow_counts, :retirement_reason, :integer
  end
end
