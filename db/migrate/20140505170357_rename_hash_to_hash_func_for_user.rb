class RenameHashToHashFuncForUser < ActiveRecord::Migration
  def change
    rename_column :users, :hash, :hash_func
  end
end
