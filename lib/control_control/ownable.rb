module ControlControl
  module Ownable
    def self.included(mod)
      mod.module_eval do
        belongs_to :owner, polymorphic: true
        validates_presence_of :owner
      end
    end

    def owner?(actor)
      owner == actor
    end
  end
end
