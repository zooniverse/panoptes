# frozen_string_literal: true

class AddMarkRemoveColumnToRecents < ActiveRecord::Migration
  disable_ddl_transaction!
  def up
    add_column :recents, :mark_remove, :boolean
    change_column_default :recents, :mark_remove, false
    remove_foreign_key :recents, :classifications

    Recent.find_in_batches do |recents|
      recents.update_all(mark_remove: false)
      sleep(0.01) # throttle the updates to the table
    end
  end

  def down
    remove_column :recents, :mark_remove
  end
end
