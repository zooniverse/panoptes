require 'devise/strategies/authenticatable'

class ZooUserWardenStrategy < Devise::Strategies::Authenticatable
  def valid?
    params['user'] && params['user']['display_name'] && params['user']['password']
  end

  def authenticate!
    zoo_home_user = ZooniverseUser.authenticate(params['user']['display_name'],
                                                params['user']['password'])
    
    if zoo_home_user && imported_user = zoo_home_user.import
      remember_me(imported_user)
      imported_user.after_database_authentication
      success!(imported_user)
    end

    if zoo_home_user.nil? || zoo_home_user && imported_user.nil?
      fail!(I18n.t("devise.failure.invalid"))
    end
  end
end


Warden::Strategies.add(:zoo_user, ZooUserWardenStrategy)
