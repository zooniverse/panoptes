class AddUserIpToClassification < ActiveRecord::Migration
  def change
    add_column :classifications, :user_ip, :inet
  end
end
