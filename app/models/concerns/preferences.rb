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
      case action.to_s
      when "show", "index"
        self.joins(:user, @preferences_for).where(:users => {private_profile: false},
          @preferences_for.to_s.pluralize => {private: false})
          .or(user.send("#{@preferences_for}_preferences"))
      else
        user.send("#{@preferences_for}_preferences")
      end
    end
  end
end
