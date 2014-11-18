module PreferencesLink
  extend ActiveSupport::Concern

  module ClassMethods
    def preferences_model(mod)
      can_be_linked mod, :preference_scope, :actor
    end

    # Users can add preferences for any project/colleciton they can see. Roles may
    # only be added by a User that has edit permissions for a project/collection
    def preference_scope(actor, type)
      case type
      when :roles
        scope_for(:update, actor)
      when :preferences
        scope_for(:show, actor)
      end
    end
  end
end
