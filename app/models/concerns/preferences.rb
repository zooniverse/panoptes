module Preferences
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    validates_presence_of :user
  end

  module ClassMethods
    def preferences_for(preference, counter_cache = false)
      @preferences_for = preference
      belongs_to @preferences_for, dependent: :destroy, counter_cache: counter_cache
      validates_presence_of @preferences_for
    end

    def scope_for(action, user, opts={})
      return all if user.is_admin?
      user.send("#{@preferences_for}_preferences")
    end
  end
end
