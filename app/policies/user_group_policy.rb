class UserGroupPolicy < ApplicationPolicy
  def read?
    true
  end

  def create?
    !user.nil?
  end

  def update?
    super || group_admin?
  end

  def delete?
    super || group_admin?
  end

  private 
  def group_admin?
    !user.nil? && user.has_role?(:group_admin, record)
  end
end
