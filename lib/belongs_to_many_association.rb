require 'array_association_scope'

class BelongsToManyAssociation < ActiveRecord::Associations::CollectionAssociation

  def association_scope
    if klass
      @association_scope ||= ArrayAssociationScope.scope(self, klass.connection)
    end
  end

  def ids_reader
    owner[reflection.foreign_key]
  end

  def ids_writer(ids)
    owner[reflection.foreign_key] = ids
  end

  def replace(other_ary)
    ids_writer(other_ary.map(&:id))
  end

  def delete_records(records, method)
    owner[reflection.foreign_key] = owner[reflection.foreign_key] - records.map(&:id)
    owner.save!
  end

  def insert_record(record, validate=true, raise=true)
    set_inverse_instance(record)

    save_method = raise ? :save! : :save
    record.send(save_method, validate: validate)
    update_owner_foreign_key(record)
    owner.send(save_method, validate: validate)
  end

  private

  def get_records
    if reflection.scope_chain.any?(&:any?) ||
        scope.eager_loading? ||
        klass.current_scope ||
        klass.default_scopes.any?
      return scope.to_a
    end

    conn = klass.connection
    sc = reflection.association_scope_cache(conn, owner) do
      ActiveRecord::StatementCache.create(conn) { |params|
        as = ArrayAssociationScope.create { params.bind }
        target_scope.merge as.scope(self, conn)
      }
    end
    binds = ArrayAssociationScope.get_bind_values(owner, reflection.chain)
    sc.execute binds, klass, klass.connection
  end

  def update_owner_foreign_key(record)
    owner[reflection.foreign_key] ||= []
    owner[reflection.foreign_key] << record.id
  end
end
