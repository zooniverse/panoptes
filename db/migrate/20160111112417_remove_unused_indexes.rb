class RemoveUnusedIndexes < ActiveRecord::Migration
  def up
    #was put in place for the aggregation engine, that never used it!
    remove_index :classifications, column: :workflow_version
    #this will be used soon for HHMI project group classificaton comparison
    remove_index :classifications, column: :user_group_id
    #this compound index is never used but the user_id one is
    remove_index :memberships, column: [ :user_id, :identity ]
    #not currently used and should only be used with a more restrictive filter
    # e.g. user_group_id: X and overlap or contains roles..
    remove_index :access_control_lists, column: :roles
    #aggregations only make sense in the context of a subejct, workflow
    # use the compound index instead
    remove_index :aggregations, column: :subject_id
    remove_index :subjects, column: :zooniverse_id
    #index is not used as it's only for sorting with more restrictive filter
    remove_index :user_project_preferences, column: :updated_at
    #compound index is used
    remove_index :user_seen_subjects, column: :workflow_id

    #duplicate index
    execute <<-SQL
      DROP INDEX IF EXISTS idx_priority_sms;
    SQL
    #malformed gin search index
    remove_index :tags, name: :tags_name_trgm_idx
    execute <<-SQL
      CREATE INDEX index_tags_name_trgrm
      ON tags
      USING gin(
        coalesce("tags"."name"::text, '')
        gin_trgm_ops
      );
    SQL
  end

  def down
    add_index :classifications, :workflow_version
    add_index :classifications, :user_group_id
    add_index :memberships, [ :user_id, :identity ]
    add_index :access_control_lists, :roles, using: :gin
    add_index :aggregations, :subject_id
    add_index :subjects, :zooniverse_id
    add_index :user_project_preferences,  :updated_at
    add_index :user_seen_subjects, :workflow_id

    remove_index :tags, name: :index_tags_name_trgrm
    add_index :tags, :name,
      operator_class: "gin_trgm_ops",
      using: :gin,
      name: "tags_name_trgm_idx"
  end
end
