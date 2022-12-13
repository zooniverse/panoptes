class JsonToJsonb < ActiveRecord::Migration
  TO_CHANGE = [
    [:aggregations, :aggregation],
    [:classifications, [:annotations, :metadata]],
    [:subject_sets, [:retirement, :metadata]],
    [:subjects, [:metadata, :locations]],
    [:user_collection_preferences, :preferences],
    [:user_project_preferences, :preferences],
    [:workflows, :tasks]
  ]

  def up
    TO_CHANGE.each do |(table, columns)|
      Array.wrap(columns).each do |column|
        change_column_default(table, column, nil)
        change_column table, column, "jsonb USING CAST(#{column} AS jsonb)"
        change_column_default(table, column, {})
      end
    end
  end

  def down
    TO_CHANGE.each do |(table, columns)|
      Array.wrap(columns).each do |column|
        change_column_default(table, column, nil)
        change_column table, column, "json USING CAST(#{column} AS json)"
        change_column_default(table, column, {})
      end
    end
  end
end
