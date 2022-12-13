class ForeignKeysFieldGuides < ActiveRecord::Migration
  def change
    add_foreign_key :field_guides, :projects, on_update: :cascade, on_delete: :cascade
  end
end
