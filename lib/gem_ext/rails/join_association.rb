require 'active_record/associations/join_dependency/join_association'

ActiveRecord::Associations::JoinDependency::JoinAssociation.class_eval do
  def build_constraint(klass, table, key, foreign_table, foreign_key)
    constraint = case reflection.macro
                 when :belongs_to_many
                   foreign_table[foreign_key].any(table[key])
                 else
                   table[key].eq(foreign_table[foreign_key])
                 end

    if klass.finder_needs_type_condition?
      constraint = table.create_and([
                                     constraint,
                                     klass.send(:type_condition, table)
                                    ])
    end
    constraint
  end
end
