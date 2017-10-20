class ClassificationExportRow < ActiveRecord::Base
  belongs_to :classification, required: true
  belongs_to :project, required: true
  belongs_to :workflow, required: true
  belongs_to :user

  validate :validate_data

  # validates_presence_of :classification, :project_id, :workflow_id, :user_id

  before_validation :copy_classification_fkeys

  def self.create_from_classification(classification)
    create!(classification: classification, data: {}) do |export_row|
      export_row.project_id = classification.project_id
      export_row.workflow_id = classification.workflow_id
      export_row.user_id = classification.user_id
    end
  end

  private

  def validate_data
    unless data.is_a?(Hash)
      errors.add(:data, "must be present but can be empty")
    end
  end
end
