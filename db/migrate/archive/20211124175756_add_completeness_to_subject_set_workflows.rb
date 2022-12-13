# frozen_string_literal: true

class AddCompletenessToSubjectSetWorkflows < ActiveRecord::Migration
  def change
    add_column :subject_sets_workflows, :completeness, :decimal, default: 0.0
  end
end
