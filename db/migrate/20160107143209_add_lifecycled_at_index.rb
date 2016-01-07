class AddLifecycledAtIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :classifications,
    :lifecycled_at,
    where: "(lifecycled_at IS NULL)",
    algorithm: :concurrently
  end
end
