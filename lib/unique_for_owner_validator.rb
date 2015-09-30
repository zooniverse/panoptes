class UniqueForOwnerValidator < ActiveModel::Validator
  def validate(record)
    record_class = record.class
    records = owner_records(record_class, record.owner)
    if records
      unique_fields_for(record).each do |field|
        if record_exists?(records, record, field)
          record.errors[field] = "Must be unique for owner"
        end
      end
    else
      record.errors[:owner] = "Must not be nil"
    end
  end

  def unique_fields_for(record)
    record.is_a?(User) ? %i(login) : %i(display_name)
  end

  def owner_records(klass, owner)
    owner.try(:send, klass.model_name.plural)
  end

  def record_exists?(scope, record, field)
    query = scope.where("lower(#{field}) = ?", record.send(field).to_s.downcase)
    query = query.where.not(id: record.id) if record.persisted?
    query.exists?
  end
end
