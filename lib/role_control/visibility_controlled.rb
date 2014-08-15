module RoleControl
  module VisibilityControlled
    extend ActiveSupport::Concern

    included do
      can :show, :check_read_roles
    end

    module ClassMethods
      def visible_to(actor)
        RoleControl::RoleQuery.new(actor,
                                   self,
                                   role_join_id)
          .build
      end
      
      protected
      
      def role_join_id
        "#{ model_name.singular }_id".to_sym
      end
      
    end

    def check_read_roles(enrolled)
      roles = enrolled.roles_query_for(self).first.try(:roles)
      return true if visible_to.empty?
      return false if roles.blank?
      !(Set.new(roles) & Set.new(visible_to.map(&:to_s))).empty?
    end
  end
end
