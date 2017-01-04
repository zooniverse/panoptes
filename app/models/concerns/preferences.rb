module Preferences
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    validates_presence_of :user
  end

  module ClassMethods
    def preferences_for(preference, opts={})
      @preferences_for = preference
      belongs_to @preferences_for, **opts
      validates_presence_of @preferences_for
      validates_uniqueness_of :user_id, scope: :"#{preference}_id"
    end

    def scope_for(action, user, opts={})
      return all if user.is_admin?
      where(user_id: user.id)
    end
  end
end
