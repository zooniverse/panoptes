require 'control_control/actor'

module RoleControl
  module Enrolled
    extend ActiveSupport::Concern
    include ControlControl::Actor

    module ClassMethods
      def roles_for(klass, role_association, roles_field=:roles)
        @roles_for ||= Hash.new
        @roles_for[klass] = [ role_association, roles_field ]
      end
      
      def roles_query_for(enrolled, target_class, target_id=nil)
        association, roles_field = @roles_for[target_class]
        target_id_field = "#{ target_class.model_name.singular }_id"

        assoc = enrolled.send(association)
        assoc = assoc.where( target_id_field => target_id ) if target_id
        assoc.select("#{ roles_field } as roles, #{ target_id_field }")
      end
    end

    def roles_query_for(target)
      self.class.roles_query_for(self, target.class, target.id)
    end
  end
end
