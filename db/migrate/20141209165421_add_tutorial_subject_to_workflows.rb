class AddTutorialSubjectToWorkflows < ActiveRecord::Migration
  def change
    add_reference :workflows, :tutorial_subject, index: true
  end
end
