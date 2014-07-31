module ControlControl
  module Ownable
    def self.included(mod)
      mod.module_eval do
        can :read, :owner?
        can :edit, :owner?
        can :destroy, :owner?
        
        belongs_to :owner, polymorphic: true
        validates_presence_of :owner
      end
    end

    def owner?(actor)
      owner == actor
    end
  end
end
