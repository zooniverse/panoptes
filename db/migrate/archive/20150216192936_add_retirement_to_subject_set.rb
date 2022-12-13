class AddRetirementToSubjectSet < ActiveRecord::Migration
  def change
    add_column :subject_sets, :retirement, :json, default: {}
  end
end
