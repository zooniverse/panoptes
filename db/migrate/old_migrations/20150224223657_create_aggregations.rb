class CreateAggregations < ActiveRecord::Migration
  def change
    create_table :aggregations do |t|
      t.references :workflow, index: true
      t.references :subject, index: true
      t.json :aggregation, null: false, default: {}

      t.timestamps
    end
  end
end
