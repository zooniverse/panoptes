module ControlControl
  module ActAs
    def can_as(action, filter=nil, &block)
      action = "#{ action }_as".to_sym
      can(action, filter, &block)
    end
  end
end
