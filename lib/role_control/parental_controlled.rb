require 'role_control/controlled'

module RoleControl
  module ParentalControlled
    include RoleControl::Controlled
    
    def can_by_role_through_parent(action, parent, *additional_roles)
      question = "can_#{ action }?".to_sym
      can(action) do |enrolled|
        begin
          send(parent).send(question, enrolled)
        rescue StandardError => e
          nil
        end
      end
      
      unless additional_roles.blank?
        can action, &test_proc(parent, additional_roles)
      end
    end

    protected

    def test_proc(parent, add_roles)
      test_proc = super(add_roles)
      proc { |enrolled| send(parent).instance_exec(enrolled, &test_proc) }
    end
  end
end
