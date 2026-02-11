class CreateOrganizationProjects < ActiveRecord::Migration[7.0]
  def up
    create_table :organization_projects do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.timestamps
    end

    add_index :organization_projects, [:organization_id, :project_id], unique: true

    safety_assured do
      execute <<~SQL.squish
        INSERT INTO organization_projects (organization_id, project_id, created_at, updated_at)
        SELECT organization_id, id, NOW(), NOW()
        FROM projects
        WHERE organization_id IS NOT NULL
        ON CONFLICT (organization_id, project_id) DO NOTHING
      SQL
    end
  end

  def down
    drop_table :organization_projects, if_exists: true
  end
end
