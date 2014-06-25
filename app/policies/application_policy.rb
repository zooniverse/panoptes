class ApplicationPolicy < Struct.new(:user, :record)
  def read?
    is_admin?
  end

  def create?
    is_admin?
  end

  def update?
    is_admin?
  end

  def destroy?
    is_admin?
  end

  private

  def is_admin?
    !user.nil? && user.has_role?(:admin)
  end
end
