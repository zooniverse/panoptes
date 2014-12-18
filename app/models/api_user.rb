class ApiUser
  attr_reader :user

  class DoChain
    attr_reader :scope, :action, :user, :block
    
    def initialize(user, action, &block)
      @action = action
      @user = user
      @block = block
    end
    
    def to(klass, context={})
      actors = if block
                 block.call(user, action)
               else
                 scope_for_user(user, action, klass)
               end
      @scope = klass.scope_for(action, actors, **context)
      self
    end

    def with_ids(ids)
      @scope = scope.where(id: ids).order(:id) unless ids.blank?
      self
    end

    private

    def scope_for_user(user, action, klass)
      user.groups_for(action, klass).try(:select, :id)
    end
  end

  delegate :groups_for, :is_admin?, :owns?, :id, :languages,
           :user_groups, :project_preferences, :collection_preferences,
           to: :user, allow_nil: true

  def initialize(user)
    @user = user
  end

  def logged_in?
    !!user
  end
  
  def owner
    user
  end

  def banned?
    logged_in? && user.banned
  end

  def do(action, &block)
    DoChain.new(self, action, &block)
  end
end
