class AddHabtmJoinIndex < ActiveRecord::Migration
  def change
    add_index :subject_sets_workflows, :subject_set_id
    add_index :subject_sets_workflows, :workflow_id
  end
end
