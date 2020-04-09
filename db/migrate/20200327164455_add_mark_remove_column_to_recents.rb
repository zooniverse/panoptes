# frozen_string_literal: true

class AddMarkRemoveColumnToRecents < ActiveRecord::Migration
  disable_ddl_transaction!
  def up
    add_column :recents, :mark_remove, :boolean
    change_column_default :recents, :mark_remove, false
    remove_foreign_key :recents, :classifications

    # find the first known recent older than 2 week
    if recent_older_than_2_weeks = Recent.first_older_than(14.days)
      # use the oldest recent id to destroy old recents
      old_recents_to_remove = Recent.where(
        'id <= ?',
        recent_older_than_2_weeks.id
      ).select(:id)

      old_recents_to_remove.find_in_batches do |recents|
        Recent.where(id: recents).destroy_all
      end
    end

    # as all remaining recents in the table are less
    # than 14 days old, mark them as ok to keep
    Recent.select(:id).find_in_batches do |recents|
      Recent.where(id: recents).update_all(mark_remove: false)
    end

    # remove recents bloated indexes after data cleanup
    %i[project_id subject_id user_id workflow_id created_at].each do |col|
      remove_index :recents, column: col if index_exists?(:recents, col)
    end
    # rebuild only recent indexes we use to access data
    add_index :recents, :project_id, algorithm: :concurrently
    add_index :recents, :user_id, algorithm: :concurrently
  end

  def down
    remove_column :recents, :mark_remove
    add_foreign_key :recents, :classifications
  end
end
