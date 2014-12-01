class RenameNameToDisplayNameForSubjectSets < ActiveRecord::Migration
  def change
    rename_column :subject_sets, :name, :display_name
  end
end
