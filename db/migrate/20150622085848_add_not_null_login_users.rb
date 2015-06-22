class AddNotNullLoginUsers < ActiveRecord::Migration
  def change
    change_column_null :users, :login, false
  end
end
