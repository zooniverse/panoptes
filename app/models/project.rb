class Project < ActiveRecord::Base
  extend RoleControl::Controlled
  include RoleControl::VisibilityControlled
  include ControlControl::Ownable
  include SubjectCounts
  include Activatable
  include Translatable

  attr_accessible :name, :display_name, :owner, :primary_language

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects

  validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  validates_uniqueness_of :display_name, scope: :owner

  can_by_role :edit, :collaborator
  can_by_role :destroy, :collaborator
end
