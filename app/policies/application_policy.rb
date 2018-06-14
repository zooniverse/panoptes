class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    scope.where(:id => record.id).exists?
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  @scopes_by_action = {}
  
  def self.scope(*actions, with:)
    actions.each do |action| 
      @scopes_by_action ||= {}
      @scopes_by_action[action] = with
    end
  end

  def self.scopes_by_action
    @scopes_by_action || {}
  end

  def scope_for(action)
    scope = if record.is_a?(Class)
              record
            else
              record.class
            end

    self.class.scopes_by_action[action].new(user, scope).resolve(action)
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
      case
      when user.is_admin?
        scope.all
      when user.logged_in?
        user_can_access_scope(
          private_query(action, user, self.class.roles),
          public_flag
        )
      when public_flag
        public_scope
      else
        scope.none
      end
    end

    def public_flag
      return false unless respond_to?(:public_scope)
      !public_scope.is_a?(ActiveRecord::NullRelation)
    end

    def user_can_access_scope(private_query, public_flag)
      accessible = scope
      accessible = accessible.where(id: private_query.select(:resource_id))
      accessible = accessible.or(public_scope) if public_flag
      accessible
    end

    def private_query(action, target, roles)
      user_group_memberships = user.memberships_for(action, model).select(:user_group_id)
      
      AccessControlList
        .where(user_group_id: user_group_memberships)
        .where(resource_type: model.model_name.name)
        .select(:resource_id)
        .where("roles && ARRAY[?]::varchar[]", roles)
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
