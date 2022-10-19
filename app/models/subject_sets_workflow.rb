# frozen_string_literal: true

class SubjectSetsWorkflow < ApplicationRecord
  belongs_to :workflow
  belongs_to :subject_set

  validates_uniqueness_of :workflow_id, scope: :subject_set_id
end
