class ConvertUseCellectToEnum < ActiveRecord::Migration
  def change
    add_column :workflows, :subject_selection_strategy, :integer, default: 0
    Workflow.where("use_cellect IS TRUE").update_all(subject_selection_strategy: Workflow.subject_selection_strategies[:cellect])
  end
end
