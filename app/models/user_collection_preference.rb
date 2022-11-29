# frozen_string_literal: true

class UserCollectionPreference < ApplicationRecord
  include Preferences

  preferences_for :collection
end
