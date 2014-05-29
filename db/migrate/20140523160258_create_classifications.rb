class CreateClassifications < ActiveRecord::Migration
  def change
    create_table :classifications do |t|
      t.references :grouped_subject, index: true
      t.references :project, index: true
      t.references :user, index: true
      t.references :workflow, index: true
      t.json :annotations

      t.timestamps
    end
  end
end
