class Project < ActiveRecord::Base
  include RoleControl::Controlled
  include RoleControl::Ownable
  include RoleControl::Adminable
  include SubjectCounts
  include Activatable
  include Translatable
  include Linkable

  attr_accessible :name, :display_name, :owner, :primary_language,
    :project_contents

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects

  validates_uniqueness_of :name, case_sensitive: false, scope: :owner
  validates_uniqueness_of :display_name, scope: :owner

  can_by_role :update, roles: [ :collaborator ] 
  can_by_role :show, public: true, roles: :visible_to

  can_be_linked :subject_set, :scope_for, :update, :actor
  can_be_linked :subject, :scope_for, :update, :actor
  can_be_linked :workflow, :scope_for, :update, :actor
end
