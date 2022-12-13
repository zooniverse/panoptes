# frozen_string_literal: true

class AddProjectRunSubjectSetCompletionEvents < ActiveRecord::Migration
  def change
    add_column :projects, :run_subject_set_completion_events, :boolean, default: false
  end
end
