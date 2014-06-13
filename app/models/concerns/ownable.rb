# Allows a Model to belong to more than one type of owner

module Ownable
  extend ActiveSupport::Concern

  included do 
    belongs_to :owner, polymorphic: true
    validates_presence_of :owner
  end

  module ClassMethods 
    def policy_class
      OwnedObjectPolicy
    end
  end

  def owner?(instance)
    instance.class < Owner && owner == instance
  end
end
