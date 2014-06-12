class UserGroupPolicy < ApplicationPolicy
  def read?
    true
  end

  def create?
    user.exists?
  end

  def update?
    super || user.has_role? :group_admin, record
  end

  def delete?
    super || user.has_role? :group_admin, record
  end
end
