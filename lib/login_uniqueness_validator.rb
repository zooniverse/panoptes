class LoginUniquenessValidator < ActiveModel::Validator
  def validate(record)
    query = record.class.where taken?, login: record.login, display_name: record.display_name
    query = query.where('id <> :id', id: record.id) unless record.new_record?
    record.errors.add(:login, 'has already been taken') if query.exists?
  end

  def taken?
    'lower(login) = lower(:login) OR lower(display_name) = lower(:display_name)'
  end
end
