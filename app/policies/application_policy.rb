class ApplicationPolicy < Struct.new(:user, :record)
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
  
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
  
  def scope
    Pundit.policy_scope! user, record.class
  end

  private

  def is_admin?
    !user.nil? && user.has_role?(:admin)
  end
end
