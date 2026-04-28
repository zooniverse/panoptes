class AddGinIndexToProjectsConfiguration < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :projects, :configuration, using: :gin, algorithm: :concurrently
  end
end
