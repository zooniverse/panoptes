class LoggedOutUser
  include RoleControl::UnrolledUser
  include ControlControl::Actor
  
  def id
    nil
  end

  def logged_in?
    false
  end

  def owner
    nil
  end
end
