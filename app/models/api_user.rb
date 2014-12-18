class ApiUser
  attr_reader :user

  delegate :is_admin?, :owns?, :id, :languages, to: :user, :allow_nil: true

  def initialize(user)
    @user = user
  end

  def logged_in?
    !!user
  end
  
  def owner
    user
  end

  def banned
    user && user.banned
  end
end
