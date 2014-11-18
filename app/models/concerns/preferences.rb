module Preferences
  extend ActiveSupport::Concern

  included do
    can :update, :allowed_to_change?
    can :destroy, :allowed_to_change?
    can :show, :allowed_to_change?
    can :update_roles, proc { |actor| send(self.class.roles_resource).can_update?(actor) }
    can :update_preferences, proc { |actor| user == actor.try(:user) }
  end

  module ClassMethods
    def visibility_query(query)
      @visibility_query = query
    end
    
    def visible_to(actor, as_admin: false)
      @visibility_query.new(actor, self).build(as_admin)
    end
    
    def can_create?(actor)
      actor.try(:logged_in?)
    end
  end

  def allowed_to_change?(actor)
    can_update_preferences?(actor) || can_update_roles?(actor)
  end
end
