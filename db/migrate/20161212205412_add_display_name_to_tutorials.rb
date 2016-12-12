class AddDisplayNameToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :display_name, :text, default: ""
  end
end
