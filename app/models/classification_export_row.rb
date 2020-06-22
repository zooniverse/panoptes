class ClassificationExportRow < ActiveRecord::Base
  belongs_to :classification, required: true
  belongs_to :project, required: true
  belongs_to :workflow, required: true
  belongs_to :user

  validates_presence_of :workflow_name, :workflow_version,
      :classification_created_at, :metadata, :annotations,
      :subject_data, :subject_ids

  def self.attributes_from_formatter(formatter)
    {
      project_id: formatter.project_id,
      workflow_id: formatter.workflow_id,
      user_id: formatter.user_id,
      user_name: formatter.user_name,
      # nil attributes will be filled in by the dump processor on each run
      user_ip: nil, # formatter.user_ip
      workflow_name: formatter.workflow_name,
      workflow_version: formatter.workflow_version,
      classification_created_at: formatter.created_at,
      gold_standard: formatter.gold_standard,
      expert: formatter.expert,
      metadata: formatter.metadata,
      annotations: formatter.annotations,
      subject_data: formatter.subject_data,
      subject_ids: formatter.subject_ids
    }
  end
end
