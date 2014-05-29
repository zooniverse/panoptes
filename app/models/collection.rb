class Collection < ActiveRecord::Base
  include Ownable

  belongs_to :project
  has_and_belongs_to_many :subjects

  validates_presence_of :owner
end
