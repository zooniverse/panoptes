class RemoveAggregationFromWorkflows < ActiveRecord::Migration[6.1]
  def change
    remove_column :workflows, :aggregation, :jsonb
  end
end
