# frozen_string_literal: true

class Aggregation < ApplicationRecord
  belongs_to :workflow
  belongs_to :project
  belongs_to :user
  validates :project, :workflow, :user, presence: true
  validates :workflow, uniqueness: true

  enum status: {
    created: 0,
    pending: 1,
    completed: 2,
    failed: 3
  }
end
