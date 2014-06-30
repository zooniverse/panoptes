class Collection < ActiveRecord::Base
  include Ownable
  include Activatable
  include Visibility
  
  attr_accessible :name, :display_name, :project_id

  belongs_to :project
  has_and_belongs_to_many :subjects

  visibility_level :private, :collaborator
end
