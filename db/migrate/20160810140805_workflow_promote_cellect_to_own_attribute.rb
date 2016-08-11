class WorkflowPromoteCellectToOwnAttribute < ActiveRecord::Migration
  def up
    add_column :workflows, :use_cellect, :boolean, index: true, default: false, null: false
    launched_workflows = Workflow.joins(:project).where("projects.launch_approved = true")
    launched_workflows.select do |w|
      config = w.configuration.with_indifferent_access
      strategy = config[:selection_strategy].try(:to_sym)
      if strategy == :cellect
        new_config = config.except(:selection_strategy)
        w.update_columns(configuration: new_config, use_cellect: true)
      end
    end
  end

  def down
    remove_column :workflows, :use_cellect
  end
end
