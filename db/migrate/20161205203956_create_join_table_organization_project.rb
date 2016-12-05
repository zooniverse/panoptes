class CreateJoinTableOrganizationProject < ActiveRecord::Migration
  def change
    create_join_table :organizations, :projects do |t|
      t.index [:organization_id, :project_id]
      t.index [:project_id, :organization_id]
    end
  end
end
