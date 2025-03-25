class AddCompleteIndexToClassifications < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :classifications,
    :completed,
    where: "(completed IS FALSE)",
    algorithm: :concurrently
  end
end
