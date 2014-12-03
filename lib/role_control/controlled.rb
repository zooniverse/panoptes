module RoleControl
  module Controlled
    extend ActiveSupport::Concern

    included do
      @roles_for = Hash.new
    end

    module ClassMethods
      include ControlControl::Resource
      include ControlControl::ActAs

      def can_by_role(action, act_as: nil, public: false, roles: nil)
        if act_as
          can_as action, &dispatch_can_as(action)
          can_as "#{ action }_#{ act_as }", &role_test_proc(action)
        else
          can action, &role_test_proc(action)
        end
        
        @roles_for[action] = RoleScope.new(roles, public, self)
      end

      def can_create?(actor, *args)
        !actor.blank?
      end

      def scope_for(action, actor, target: nil, extra_test: [])
        @roles_for[action].build(actor, target, extra_test)
      end

      protected

      def dispatch_can_as(action)
        proc do |enrolled, target|
          begin
            klass = target.is_a?(Class) ? target : target.class
            send("can_#{ action }_#{ klass }_as?", enrolled)
          rescue NoMethodError
            false
          end
        end
      end

      def role_test_proc(action)
        proc do |enrolled|
          self.class.scope_for(action, enrolled, target: self).exists?(self)
        end
      end
    end
  end
end
