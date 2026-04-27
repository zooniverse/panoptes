# frozen_string_literal: true

class RemoveAggregationFromWorkflows < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :workflows, :aggregation, :jsonb }
  end
end
