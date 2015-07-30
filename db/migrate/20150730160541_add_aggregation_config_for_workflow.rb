class AddAggregationConfigForWorkflow < ActiveRecord::Migration
  def change
    add_column :workflows, :aggregation, :json, default: {}, null: false
  end
end
