# frozen_string_literal: true

class AddMarkRemoveColumnToRecents < ActiveRecord::Migration
  def up
    add_column :recents, :mark_remove, :boolean
    change_column_default :recents, :mark_remove, false
  end

  def down
    remove_column :recents, :mark_remove
  end
end
