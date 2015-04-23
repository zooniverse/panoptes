class ArrayAssociationScope < ActiveRecord::Associations::AssociationScope

  def self.scope(association, connection)
    INSTANCE.scope association, connection
  end

  INSTANCE = create

  def last_chain_scope(scope, table, reflection, owner, tracker, assoc_klass)
    join_keys = reflection.join_keys(assoc_klass)
    key = join_keys.key
    foreign_key = join_keys.foreign_key
    scope = scope.where(table[key].in(owner[foreign_key]))
  end

  def next_chain_scope(scope, table, reflection, tracker, assoc_klass, foreign_table, next_reflection)
    join_keys = reflection.join_keys(assoc_klass)
    key = join_keys.key
    foreign_key = join_keys.foreign_key
    constraint = foreign_table[foreign_key].any(table[key])
    scope = scope.joins(join(foreign_table, constraint))
  end
end
