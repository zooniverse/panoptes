class SubjectSetsWorkflow < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :subject_set

  validates_uniqueness_of :workflow_id, scope: :subject_set_id
end
