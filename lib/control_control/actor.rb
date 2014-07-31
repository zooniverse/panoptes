module ControlControl
  module Actor
    def _do_to_resource_on_behalf_of(resource, action, target, &block)
      action_question = "can_#{ action }_as?".to_sym
      if resource.send(action_question, target, self)
        resource.do_to_resource(target, action, &block)
      else
        raise AccessDenied.new("Insufficient permissions to access resource")
      end
    end

    def do_to_resource(resource, action, as: nil, &block)
      if as
        return _do_to_resource_on_behalf_of(as, action, resource, &block)
      end
      
      action_question = "can_#{ action }?".to_sym
      if resource.send(action_question, self)
        block.call(self, resource)
      else
        raise AccessDenied.new("Insufficient permissions to access resource")
      end
    end
  end
end
