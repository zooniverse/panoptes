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
        @enrolled_for[controlled_class] = through

        define_method :"#{ controlled }_for" do |action=:show|
          controlled_class.scope_for(action, self)
        end
      end

      def roles_for(enrolled, target)
        if target.is_a?(Class)
          enrolled.send(@enrolled_for[target]).roles_query
        else
          enrolled.send(@enrolled_for[target.class]).roles_query(resource: target)
        end
      end
    end

    def global_scopes(query)
      query
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
