class AddIndexToPriority < ActiveRecord::Migration
  def change
    add_index :set_member_subjects, :priority
  end
end
