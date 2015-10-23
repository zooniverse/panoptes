class AddDefaultToCollectionPrivate < ActiveRecord::Migration
  def change
    private_setting = true
    change_column :collections, :private, :boolean, default: private_setting
    Collection.where(private: nil).update_all(private: private_setting)
    change_column_null :collections, :private, false
  end
end
