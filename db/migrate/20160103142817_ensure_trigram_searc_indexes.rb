class EnsureTrigramSearcIndexes < ActiveRecord::Migration
  def up
    tables = %i(projects collections user_groups)
    tables.each do |table|
      remove_index table, name: "#{table}_display_name_trgm_index"
      execute <<-SQL
        CREATE INDEX "index_#{table}_display_name_trgrm"
        ON "#{table}"
        USING gin(
          coalesce("#{table}"."display_name"::text, '')
          gin_trgm_ops
        );
      SQL
    end
  end

  def down
    tables = %i(projects collections user_groups)
    tables.each do |table|
      remove_index table, name: "index_#{table}_display_name_trgrm"
      add_index table, :display_name,
        name: "#{table}_display_name_trgm_index",
        operator_class: :gist_trgm_ops,
        using: :gist
    end
  end
end
