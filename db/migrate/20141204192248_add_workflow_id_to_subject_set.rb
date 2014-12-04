class AddWorkflowIdToSubjectSet < ActiveRecord::Migration
  def change
    add_reference :subject_sets, :workflow, index: true
  end
end
