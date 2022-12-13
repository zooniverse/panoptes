class ReAddClassificationIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :classifications, :created_at, algorithm: :concurrently
    add_index :classifications, :user_id, algorithm: :concurrently

    add_index :classifications,
    :lifecycled_at,
    where: "(lifecycled_at IS NULL)",
    algorithm: :concurrently
  end
end
