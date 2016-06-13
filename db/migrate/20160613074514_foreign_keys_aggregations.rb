class ForeignKeysAggregations < ActiveRecord::Migration
  def change
    Aggregation.joins("LEFT OUTER JOIN workflows ON workflows.id = aggregations.workflow_id").where("aggregations.workflow_id IS NOT NULL AND workflows.id IS NULL").delete_all
    add_foreign_key :aggregations, :workflows, on_update: :cascade, on_delete: :cascade
    add_foreign_key :aggregations, :subjects, on_update: :cascade, on_delete: :cascade
  end
end
