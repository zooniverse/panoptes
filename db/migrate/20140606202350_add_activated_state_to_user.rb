class AddActivatedStateToUser < ActiveRecord::Migration
  def change
    add_column :users, :activated_state, :integer, default: 0, null: false
  end
end
