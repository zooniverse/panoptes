class Subject < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Ownable
  include RoleControl::Adminable

  belongs_to :project
  has_and_belongs_to_many :collections
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects

  validates_presence_of :project
end
