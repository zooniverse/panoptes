class ApiUser
  include RoleControl::Actor
  
  attr_reader :user

  delegate :memberships_for, :is_admin?, :owns?, :id, :languages,
           :user_groups, :project_preferences, :collection_preferences,
           :classifications, :user_groups, to: :user, allow_nil: true

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
end
