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


  def belongs_to_project?(other_project_id)
    project_id == other_project_id
  end
end
