class SubjectSet < ActiveRecord::Base

  belongs_to :project
  has_many :subject_sets_workflows, dependent: :destroy
  has_many :workflows, through: :subject_sets_workflows

  has_many :set_member_subjects, dependent: :destroy
  has_many :subjects, through: :set_member_subjects
  has_many :subject_set_imports, dependent: :destroy
  has_one :classifications_export,
          -> { where(type: 'subject_set_classifications_export').order(created_at: :desc) },
          class_name: 'Medium',
          as: :linked,
          inverse_of: :linked

  validates_presence_of :project

  validates_uniqueness_of :display_name, scope: :project_id

  scope :expert_sets, -> { where(expert_set: true) }

  delegate :communication_emails, to: :project

  def belongs_to_project?(other_project_id)
    project_id == other_project_id
  end

  # custom AR scope to find the classifications that belong to this subject set
  #
  # it will return classifications for all workflows that this set is linked to
  # it will not return classifiations for subjects across projects
  def classifications
    Classification
      .where(workflow: workflow_ids)
      .joins('INNER JOIN classification_subjects ON classifications.id = classification_subjects.classification_id')
      .where(classification_subjects: { subject_id: set_member_subjects.select(:subject_id) })
  end

  # delegate method to project but with a more succinct name
  def run_completion_events?
    project.run_subject_set_completion_events?
  end
end
