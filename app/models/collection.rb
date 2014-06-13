class Collection < ActiveRecord::Base
  include Ownable
  include Activatable
  include Visibility

  belongs_to :project
  has_and_belongs_to_many :subjects

  visibility_level :private, :collaborator
end
