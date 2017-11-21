class RebuildClassificationIndexes < ActiveRecord::Migration
  disable_ddl_transaction!
  TABLE_NAME = :classifications

  def change
    index_cols.each do |column|
      rebuild_index(column) do
        add_index TABLE_NAME, column, algorithm: :concurrently
      end
    end

    sparse_index_rebuilds.each do |column, clause|
      rebuild_index(column) do
        add_index TABLE_NAME, column, where: clause, algorithm: :concurrently
      end
    end
  end

  private

  def rebuild_index(column)
    renamed_index_name = to_delete_index_name(column)
    rename_index TABLE_NAME, current_index_name(column), renamed_index_name
    yield
    remove_index TABLE_NAME, name: renamed_index_name
  end

  def index_cols
    %i(created_at workflow_id user_id)
  end

  def sparse_index_rebuilds
    {
      gold_standard: "gold_standard IS TRUE",
      lifecycled_at: "lifecycled_at IS NULL"
    }
  end

  def current_index_name(column)
    index_name(TABLE_NAME, column)
  end

  def to_delete_index_name(column)
    "to_delete_#{column}_index"
  end
end
