class ArrayAssociationScope < ActiveRecord::Associations::AssociationScope

  def self.scope(association, connection)
    INSTANCE.scope association, connection
  end

  class BindSubstitution
    def initialize(block)
      @block = block
    end

    def bind_value(scope, column, value, alias_tracker)
      substitute = alias_tracker.connection.substitute_at(column)
      cast_type = ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array
        .new(column.cast_type)
      array_column = ActiveRecord::ConnectionAdapters::PostgreSQLColumn
        .new(column.name,
             column.default,
             cast_type,
             column.sql_type,
             column.null,
             column.default_function)
      scope.bind_values += [[array_column, @block.call(value)]]
      substitute
    end
  end

  def self.create(&block)
    block = block ? block : lambda { |val| val }
    new BindSubstitution.new(block)
  end

  INSTANCE = create

  def last_chain_scope(scope, table, reflection, owner, tracker, assoc_klass)
    join_keys = reflection.join_keys(assoc_klass)
    key = join_keys.key
    foreign_key = join_keys.foreign_key
    bind_val = bind scope, table.table_name, key.to_s, owner[foreign_key], tracker
    value = Arel::Nodes::NamedFunction.new('ANY', [bind_val])
    scope = scope.where(table[key].eq(value))
  end

  def next_chain_scope(scope, table, reflection, tracker, assoc_klass, foreign_table, next_reflection)
    join_keys = reflection.join_keys(assoc_klass)
    key = join_keys.key
    foreign_key = join_keys.foreign_key
    constraint = foreign_table[foreign_key].any(table[key])
    scope = scope.joins(join(foreign_table, constraint))
  end
end
