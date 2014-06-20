class AddLangaugesToUser < ActiveRecord::Migration
  def change
    add_column :users, :languages, :string, array: true
  end
end
