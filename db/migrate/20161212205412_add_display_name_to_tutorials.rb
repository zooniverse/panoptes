class AddDisplayNameToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :display_name, :text, default: ""
    Tutorial.update_all(display_name: "")
  end
end
