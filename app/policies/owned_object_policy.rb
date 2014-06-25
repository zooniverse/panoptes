class OwnedObjectPolicy < ApplicationPolicy
  def read?
    super || is_owner? || record.has_access?(user)
  end

  def create?
    !user.nil?
  end

  def update?
    super || is_owner?
  end

  def destroy?
    super || is_owner?
  end

  private 
  def is_owner?
    !user.nil? && user.owns?(record)
  end
end
