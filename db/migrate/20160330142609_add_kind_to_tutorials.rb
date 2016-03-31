class AddKindToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :kind, :string

    add_index :tutorials, :kind
  end
end
