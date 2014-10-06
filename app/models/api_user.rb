class ApiUser
  include ControlControl::Actor

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def logged_in?
    !!user
  end
  
  def is_admin?
    !!user.try(:admin)
  end

  def owner
    user
  end

  def owns?(model)
    user.try(:owns?, model)
  end

  def id
    user.try(:id)
  end

  def languages
    user.try(:languages)
  end

  def empty_roles
    Struct.new(:roles).new([])
  end

  def roles_query(target)
    user.try(:roles_query, target) || empty_roles 
  end

  def roles_for(target)
    user.try(:roles_for, target)
  end
end
