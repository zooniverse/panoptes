require 'role_control/controlled'

module RoleControl
  module ParentalControlled
    extend ActiveSupport::Concern
    include RoleControl::Controlled
    
    module ClassMethods
      include RoleControl::Controlled::ClassMethods
      
      def can_by_role_through_parent(action, parent, *additional_roles)
        question = "can_#{ action }?".to_sym
        can action, &test_parent(parent, question)
        
        unless additional_roles.blank?
          can action, &role_test_proc(parent, additional_roles)
        end
      end

      protected

      def test_parent(parent, question)
        proc do |enrolled|
          begin
            send(parent).send(question, enrolled)
          rescue NoMethodError => e
            nil
          end
        end
      end
      

      def role_test_proc(parent, add_roles)
        proc do |enrolled|
          !(enrolled.roles_for(send(parent)) & add_roles.map(&:to_s)).blank?
        end
      end
    end
  end
end
