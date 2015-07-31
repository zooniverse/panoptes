class AddAggregationConfigForWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :aggregation, :jsonb, default: {}, null: false
    add_index :workflows, name: "index_workflows_on_aggregation", expression: "(aggregation ->> 'public')"
  end
end
