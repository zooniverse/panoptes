class OwnedObjectPolicy < ApplicationPolicy
  def read?
    super || user.owns?(record) || record.has_access? user
  end

  def create?
    user.exists?
  end

  def update?
    super || user.owns?(record)
  end

  def delete?
    super || user.owns?(record)
  end
end
