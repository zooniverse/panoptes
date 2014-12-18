class UserCollectionPreference < ActiveRecord::Base
  include Preferences

  preferences_for :collection
end
