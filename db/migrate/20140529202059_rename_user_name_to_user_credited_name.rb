class RenameUserNameToUserCreditedName < ActiveRecord::Migration
  def change
    rename_column :users, :name, :credited_name
  end
end
