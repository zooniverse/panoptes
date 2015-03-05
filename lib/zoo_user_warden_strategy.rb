Warden::Strategies.add(:zoo_user) do
  def valid?
   params['user'] && params['user']['display_name'] && params['user']['password']
  end

  def authenticate!
    u = ZooniverseUser.authenticate(params['user']['display_name'], params['user']['password'])
    if u.nil?
      fail!("Could not log in")
    else
      success!(u.import)
    end
  end
end
