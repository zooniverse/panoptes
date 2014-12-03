module ControlControl
  module ActAs
    def can_as(action, filter=nil, &block)
      action = "#{ action }_as"
      can(action, filter, &block)
    end
  end
end
