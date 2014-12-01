class Subject < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Ownable
  include RoleControl::Adminable
  include Linkable

  has_paper_trail only: [:metadata, :locations]

  belongs_to :project
  has_and_belongs_to_many :collections
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects

  validates_presence_of :project

  def self.scope_for(action, actor)
    if action == :show
      all
    else
      actor.owner.subjects
    end
  end

  def self.can_create?(actor)
    true
  end

  def migrated_subject?
    !!migrated
  end
end
