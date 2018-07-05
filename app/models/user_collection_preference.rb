class UserCollectionPreference < ActiveRecord::Base
  include Preferences
  include RoleControl::PunditInterop

  preferences_for :collection
end
