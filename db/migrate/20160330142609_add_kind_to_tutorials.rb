class AddKindToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :kind, :string
  end
end
