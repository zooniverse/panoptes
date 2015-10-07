class AddDefaultTutorialToProject < ActiveRecord::Migration
  def change
    add_reference :projects, :default_tutorial, index: true
    add_foreign_key :projects, :tutorials, column: :default_tutorial_id
  end
end
