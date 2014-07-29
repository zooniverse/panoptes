class Collection < ActiveRecord::Base
  include ControlControl::Resource
  include ControlControl::Ownable
  include Activatable
  include Visibility
  
  attr_accessible :name, :display_name, :project_id

  belongs_to :project
  has_and_belongs_to_many :subjects

  visibility_level :private, :collaborator
  
  validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  validates_uniqueness_of :display_name, scope: :owner
end
