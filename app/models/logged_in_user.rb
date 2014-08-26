class LoggedInUser
  extend Forwardable
  include ControlControl::Actor

  attr_reader :user

  def_delegators :user, :id, :languages

  def initialize(user)
    @user = user
  end

  def logged_in?
    true
  end
  
  def is_admin?
    user.admin
  end

  def owner
    user
  end

  def roles_query(target)
    user.roles_query(target)
  end

  def roles_for(target)
    user.roles_for(target)
  end
end
