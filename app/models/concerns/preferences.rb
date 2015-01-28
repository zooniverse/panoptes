module Preferences
  extend ActiveSupport::Concern

  included do
    belongs_to :user, dependent: :destroy
    validates_presence_of :user
  end

  module ClassMethods
    def preferences_for(preference)
      @preferences_for = preference
      belongs_to @preferences_for, dependent: :destroy
      validates_presence_of @preferences_for
    end
    
    def scope_for(action, user, opts={})
      user.send("#{@preferences_for}_preferences")
    end
  end
end
