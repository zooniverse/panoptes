class AssociateWorkflowsWithTutorials < ActiveRecord::Migration
  def change
    create_table :workflow_tutorials do |t|
      t.references :workflow
      t.references :tutorial
    end
  end
end
