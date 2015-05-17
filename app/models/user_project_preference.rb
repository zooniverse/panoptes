class UserProjectPreference < ActiveRecord::Base
  include Preferences

  preferences_for :project, :classifiers_count
end
