class AddWorkflowCompletenessToSubjectSet < ActiveRecord::Migration
  def change
    # since PG v11+ we can add a new column and a default at the same time
    # https://github.com/ankane/strong_migrations#bad-1
    # https://www.2ndquadrant.com/en/blog/add-new-table-column-default-value-postgresql-11/
    add_column :subject_sets, :completeness, :jsonb, default: {}
  end
end
