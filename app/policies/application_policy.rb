class ApplicationPolicy < Struct.new(:user, :record)
  def read?
    user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def delete?
    user.admin?
  end
end
