# frozen_string_literal: true

class Aggregation < ApplicationRecord
  belongs_to :workflow
  belongs_to :project
  belongs_to :user
  validates :project, presence: true
  validates :workflow, presence: true
  validates :user, presence: true
  validates :user_id, uniqueness: { scope: :workflow_id }

  enum status: {
    created: 0,
    pending: 1,
    completed: 2,
    failed: 3
  }
end
