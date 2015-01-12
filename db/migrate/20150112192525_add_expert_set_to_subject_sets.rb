class AddExpertSetToSubjectSets < ActiveRecord::Migration
  def change
    add_column :subject_sets, :expert_set, :boolean
  end
end
