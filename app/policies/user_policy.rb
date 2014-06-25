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

  def destroy?
    super || user == record
  end
end
