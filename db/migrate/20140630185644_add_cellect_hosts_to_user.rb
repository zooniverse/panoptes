class AddCellectHostsToUser < ActiveRecord::Migration

  def change
    enable_extension "hstore"
    add_column :users, :cellect_hosts, :hstore, default: {}
  end
end
