class UserCollectionPreference < ApplicationRecord
  include Preferences

  preferences_for :collection
end
