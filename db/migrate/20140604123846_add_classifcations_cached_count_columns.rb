class AddClassifcationsCachedCountColumns < ActiveRecord::Migration
  def change
    existing_count_tables = [ :workflows, :set_member_subjects, :projects ]
    existing_count_tables.each do |table_name|
      remove_column table_name, :classification_count, :integer
    end

    new_count_tables = existing_count_tables << :users
    new_count_tables.each do |table_name|
      add_column table_name, :classifications_count, :integer, default: 0, null: false
    end
  end
end
