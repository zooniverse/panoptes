class SubjectSet < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  
  belongs_to :project
  belongs_to :workflow
  
  has_many :set_member_subjects
  has_many :subjects, through: :set_member_subjects

  validates_presence_of :project

  DEFAULT_CRITERIA = 'classification_count'
  DEFAULT_OPTS = { 'count' => 15 }

  validate do |set|
    criteria = %w(classification_count)
    unless set.retirement.empty? || criteria.include?(set.retirement['criteria'])
      set.errors.add(:"retirement.criteria", "Retirement criteria must be one of #{criteria.join(', ')}")
    end
  end

  scope :expert_sets, -> { where(expert_set: true) }

  can_through_parent :project, :update, :show, :destroy, :index, :update_links,
                     :destroy_links
  
  can_be_linked :workflow, :same_project?, :model
  can_be_linked :set_member_subject, :scope_for, :update, :user

  def self.same_project?(workflow)
    where(project: workflow.project)
  end

  def retire_member?(sms)
    retirement_scheme.retire?(sms)
  end

  def retirement_scheme
    case retirement.fetch('criteria', DEFAULT_CRITERIA)
    when 'classification_count'
      params = retirement.fetch('options', DEFAULT_OPTS).values_at('count')
      RetirementSchemes::ClassificationCount.new(*params)
    else
      raise StandardError, 'invalid retirement scheme'
    end
  end
end
