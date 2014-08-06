require 'role_control/controlled'

module RoleControl
  module ParentalControlled
    include RoleControl::Controlled
      
    def can_by_role_through_parent(action, parent, *additional_roles)
      question = "can_#{ action }?"
      can(action) { |enrolled| send(parent).send(question, enrolled) }
      unless additional_roles.blank?
        
        can action, &test_proc(parent, additional_roles)
      end
    end

    def test_proc(parent, add_roles)
      test_proc = super(add_roles)
      proc do |enrolled|
        send(parent).instance_eval do
         test_proc.call(enrolled)
        end
      end
    end
  end
end
