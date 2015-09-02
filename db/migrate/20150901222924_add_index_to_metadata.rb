class AddIndexToMetadata < ActiveRecord::Migration
  def change
    add_index :subject_sets, :metadata, using: :gin
  end
end
