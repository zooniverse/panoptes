class AddDisplayNameToTutorials < ActiveRecord::Migration
  def change
    add_column :tutorials, :display_name, :text, default: ""
    Tutorial.find_each do |tut|
      tut.display_name = ""
      tut.save!
    end
  end
end
