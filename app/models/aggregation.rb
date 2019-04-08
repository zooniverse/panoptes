class Aggregation < ActiveRecord::Base

  belongs_to :workflow
  belongs_to :subject

  validates_presence_of :workflow, :subject, :aggregation
  validates_uniqueness_of :subject_id, scope: :workflow_id
  validate :aggregation, :workflow_version_present

  private

  def workflow_version_present
    wv_key = :workflow_version
    if aggregation && !aggregation.symbolize_keys.has_key?(wv_key)
      errors.add(:aggregation, "must have #{wv_key} metadata")
    end
  end
end
