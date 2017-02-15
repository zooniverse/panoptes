class RemoveRecentsForeignKeys < ActiveRecord::Migration
  def change
    remove_foreign_key :recents, :projects if foreign_key_exists?(:recents, :projects)
    remove_foreign_key :recents, :workflows if foreign_key_exists?(:recents, :workflows)
    remove_foreign_key :recents, :users if foreign_key_exists?(:recents, :users)
  end

  # Backported from Rails 5: https://github.com/rails/rails/blob/868d859a882f2a5e97c6ac019483a8e0e611b549/activerecord/lib/active_record/connection_adapters/abstract/schema_statements.rb#L959
  def foreign_key_exists?(from_table, to_table)
    foreign_key_for(from_table, to_table).present?
  end

  def foreign_key_for(from_table, to_table) # :nodoc:
    return unless supports_foreign_keys?
    foreign_keys(from_table).detect {|fk| fk.to_table == to_table.to_s }
  end

end
