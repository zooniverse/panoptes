class CreateSubjectGroups < ActiveRecord::Migration
  def change
    create_table :subject_groups do |t|
      t.string :name
      t.references :project, index: true

      t.timestamps
    end
  end
end
