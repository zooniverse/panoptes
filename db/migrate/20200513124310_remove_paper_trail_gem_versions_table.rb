class RemovePaperTrailGemVersionsTable < ActiveRecord::Migration
  def change
    drop_table :versions do |t|
      t.string   'item_type',      null: false
      t.integer  'item_id',        null: false
      t.string   'event',          null: false
      t.string   'whodunnit'
      t.text     'object'
      t.datetime 'created_at'
      t.text     'object_changes'
    end
  end
end
