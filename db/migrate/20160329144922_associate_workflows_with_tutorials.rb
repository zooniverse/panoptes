class AssociateWorkflowsWithTutorials < ActiveRecord::Migration
  def change
    create_table :workflow_tutorials do |t|
      t.references :workflow
      t.references :tutorial
    end

    add_index :workflow_tutorials, :workflow_id
    add_index :workflow_tutorials, :tutorial_id
    add_index :workflow_tutorials, [:workflow_id, :tutorial_id], unique: true

    add_foreign_key :workflow_tutorials, :workflows, on_delete: :cascade
    add_foreign_key :workflow_tutorials, :tutorials, on_delete: :cascade
  end
end
