Warden::Strategies.add(:zoo_user) do
  def valid?
   params['user'] && params['user']['display_name'] && params['user']['password']
  end

  def authenticate!
    zoo_home_user = ZooniverseUser.authenticate(params['user']['display_name'],
                                                params['user']['password'])
    imported_user = zoo_home_user.import if zoo_home_user
    imported_user ? success!(imported_user) : fail!("Invalid display_name or password.")
  end
end
