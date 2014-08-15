require 'control_control/actor'

module RoleControl
  module Enrolled
    extend ActiveSupport::Concern
    include ControlControl::Actor

    included do
      @enrolled_for = Hash.new
    end

    module ClassMethods
      def enrolled_for(controlled, class_name: nil, through: nil)
        controlled_class = class_name ? class_name : controlled.to_s.classify.constantize
        p controlled_class
        @enrolled_for[controlled_class] = through

        define_method controlled do |action|
          controlled_class.scope_for(action, self)
        end
      end
      
      def roles_for(enrolled, target)
        target_class = target.is_a?(Class) ? target : target.class
        send(@enrolled_for[target_class]).roles_query(enrolled)
      end
    end

    def roles_query(target)
      query = self.class.roles_for(self, target)
      return query if target.is_a?(Class)
      target_id = "#{ target.class.model_name.singular }_id".to_sym
      query.where( target_id => target.id )
    end

    def roles_for(target)
      roles_query(target).first.try(:roles)
    end
  end
end

