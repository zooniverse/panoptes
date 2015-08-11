class AddExpiresToMedium < ActiveRecord::Migration
  def change
    add_column :media, :put_expires, :integer
    add_column :media, :get_expires, :integer
  end
end
