class ApplicationPolicy
  class UnknownAction < StandardError; end

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # we use this setup so that a policy can have different scopes for different actions,
  # e.g. a WriteScope and a ReadScope. you'll see this method called in a policy class like:
  # scope :update, :destroy, with: WriteScope
  def self.scope(*actions, with:)
    actions.each do |action|
      @scopes_by_action ||= {}
      @scopes_by_action[action] = with
    end
  end

  def self.scopes_by_action
    @scopes_by_action || {}
  end

  def policy_for(model)
    Pundit.policy!(user, model)
  end

  def scope_klass_for(action)
    scope_klass = self.class.scopes_by_action[action]
    if scope_klass.present?
      scope_klass
    else
      raise UnknownAction, "Action #{action.inspect} not defined for #{self}"
    end
  end

  def scope_for(action)
    scope = if record.is_a?(Class)
              record
            elsif record.is_a?(ActiveRecord::Relation)
              record
            else
              record.class
            end
    scope_klass_for(action).new(user, scope).resolve(action)
  end

  def linkable_for(relation)
    public_send("linkable_#{relation.to_s.pluralize}")
  end

  class Scope
    def self.roles_for_private_scope(roles)
      @roles ||= []
      @roles = roles
    end

    def self.roles
      @roles || []
    end

    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve(action = nil)
      if user.is_admin?
        scope.all
      elsif user.logged_in?
        user_can_access_scope(
          private_query(action, self.class.roles)
        )
      elsif public_flag
        public_scope
      else
        scope.none
      end
    end

    def public_flag
      return false unless respond_to?(:public_scope)
      !public_scope.is_a?(ActiveRecord::NullRelation)
    end

    def user_can_access_scope(private_query)
      accessible = scope.where(id: private_query.select(:resource_id))
      accessible = accessible.or(public_scope) if public_flag
      accessible
    end

    def private_query(action, roles)
      user_group_memberships = user.memberships_for(action, model).select(:user_group_id)

      AccessControlList
        .where(user_group_id: user_group_memberships)
        .where(resource_type: model.model_name.name)
        .select(:resource_id)
        .where("roles && ARRAY[?]::varchar[]", roles)
    end

    def policy_for(model)
      Pundit.policy!(user, model)
    end

    def model
      if scope.is_a?(ActiveRecord::Relation)
        scope.klass
      else
        scope
      end
    end
  end
end
