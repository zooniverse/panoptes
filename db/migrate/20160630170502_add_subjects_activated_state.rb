class AddSubjectsActivatedState < ActiveRecord::Migration
  def change
    add_column :subjects, :activated_state, :integer, default: 0, null: false
  end
end
