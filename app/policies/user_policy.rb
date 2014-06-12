class UserPolicy < ApplicationPolicy
  def read?
    true
  end

  def create?
    true
  end

  def update?
    super || user == record
  end

  def delete?
    super || user == record
  end
end
