# frozen_string_literal: true

class CreateOrganizationProjects < ActiveRecord::Migration[7.0]
  def up
    create_table :organization_projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.timestamps
    end

    add_index :organization_projects, %i[organization_id project_id], unique: true
  end

  def down
    drop_table :organization_projects, if_exists: true
  end
end
