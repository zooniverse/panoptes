class RemoveWorkflowAddProjectToTutorial < ActiveRecord::Migration
  def change
    remove_reference :tutorials, :workflow, index: true
    remove_foreign_key :projects, column: :default_tutorial_id
    remove_reference :projects, :default_tutorial, index: true
    add_reference :tutorials, :project, index: true, foreign_key: true, null: false
  end
end
