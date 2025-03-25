# frozen_string_literal: true

class UpdateWorkflowsAddFirstTaskDefaultValue < ActiveRecord::Migration[5.0]
  def change
    change_column_default(:workflows, :first_task, from: nil, to: '')
  end
end
