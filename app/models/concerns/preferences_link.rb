module PreferencesLink
  extend ActiveSupport::Concern

  module ClassMethods
    def preferences_model(mod)
      can_be_linked mod, :scope_for, :show, :user
    end
  end
end
