class Project < ActiveRecord::Base
  include Ownable
  include SubjectCounts
  include Activatable
  include Visibility
  include Translatable

  attr_accessible :name, :display_name, :owner, :primary_language

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects

  visibility_level :dev, :collaborator
  visibility_level :beta, :collaborator, :beta_tester, :scientist, :translator
  visibility_level :private, :collaborator, :scientist, :invited

  validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  validates_uniqueness_of :display_name, scope: :owner
end
