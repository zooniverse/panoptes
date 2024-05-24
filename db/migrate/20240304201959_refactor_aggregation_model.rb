# frozen_string_literal: true

class RefactorAggregationModel < ActiveRecord::Migration[6.1]
  def up
    # delete existing unused columns
    safety_assured { remove_column :aggregations, :subject_id }
    safety_assured { remove_column :aggregations, :aggregation }

    # and the new aggregations columns
    add_column :aggregations, :project_id, :integer
    add_foreign_key :aggregations, :projects, column: :project_id, validate: false

    add_column :aggregations, :user_id, :integer
    add_foreign_key :aggregations, :users, column: :user_id, validate: false

    add_column :aggregations, :uuid, :string
    add_column :aggregations, :task_id, :string
    add_column :aggregations, :status, :integer, default: 0
  end

  def down
    add_column :aggregations, :subject_id, :integer
    add_column :aggregations, :aggregation, :jsonb

    remove_column :aggregations, :user_id
    remove_column :aggregations, :project_id
    remove_column :aggregations, :uuid
    remove_column :aggregations, :task_id
    remove_column :aggregations, :status
  end
end
