# Allows a Model to belong to more than one type of owner

module Ownable
  extend ActiveSupport::Concern

  included do 
    belongs_to :owner, polymorphic: true
    validates_presence_of :owner
  end

  def owner?(instance)
    owner == instance
  end
end
