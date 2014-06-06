class Collection < ActiveRecord::Base
  include Ownable
  include Activateable

  belongs_to :project
  has_and_belongs_to_many :subjects
end
