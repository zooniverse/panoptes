class AddExternalIdToSubjects < ActiveRecord::Migration
  def change
    add_column :subjects, :external_id, :string
  end
end
