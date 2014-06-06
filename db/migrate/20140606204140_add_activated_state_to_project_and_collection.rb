class AddActivatedStateToProjectAndCollection < ActiveRecord::Migration
  def change
    [:projects, :collections, :user_groups].each do |t|
      add_column t, :activated_state, :integer, default: 0, null: false
    end
  end
end
