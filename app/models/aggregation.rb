# frozen_string_literal: true

class Aggregation < ApplicationRecord
  belongs_to :workflow
  belongs_to :user
  validates :workflow, presence: true
  validates :user, presence: true
  validates :user_id, uniqueness: { scope: :workflow_id }

  self.ignored_columns = ["subject_id", "aggregation"]

  enum status: [:pending, :completed, :failed]
end
