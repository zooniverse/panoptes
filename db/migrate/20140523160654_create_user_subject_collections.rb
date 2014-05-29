class CreateUserSubjectCollections < ActiveRecord::Migration
  def change
    create_table :user_subject_collections do |t|
      t.string :name
      t.references :project, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end
