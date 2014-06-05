class AddIdsToSubject < ActiveRecord::Migration
  def change
    table_name = :subjects
    owner_col = :owner_id
    project_col = :project_id

    add_column table_name, owner_col, :integer
    add_column table_name, project_col, :integer
    add_column table_name, :owner_type, :string, null: true

    add_index  table_name, owner_col
    add_index  table_name, project_col
  end
end
