require 'control_control/actor'

module RoleControl
  module Enrolled
    include ControlControl::Actor

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def roles_for(association, role_association, roles_field=:roles)
        @roles_for ||= Hash.new
        target_class = self.reflect_on_association(association).klass
        @roles_for[target_class] = [  role_association, roles_field ]
      end
      
      def roles_query_for(enrolled, target_class, target_id=nil)
        association, roles_field = @roles_for[target_class]
        singular = target_class.model_name.singular
        
        assoc = enrolled.send(association)
        assoc = assoc.where({ "#{ singular }_id" => target.id }) if target_id
        assoc.select("#{ roles_field } as roles, #{ singular }_id")
      end
    end

    def roles_query_for(target)
      self.class.roles_query_for(self, target.class, target.id)
    end
  end
end
