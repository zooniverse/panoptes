class LoggedOutUser
  include RoleControl::UnrolledUser

  def id
    nil
  end

  def logged_in?
    false
  end
end
