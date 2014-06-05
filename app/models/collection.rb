class Collection < ActiveRecord::Base
  include Ownable

  belongs_to :project
  has_and_belongs_to_many :subjects

  def to_param
    "#{owner.name}+#{self.name}"
  end
end
