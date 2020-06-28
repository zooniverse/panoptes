class ClassificationExport
  def self.hash_format(formatter)
    {
      project_id: formatter.project_id,
      workflow_id: formatter.workflow_id,
      user_id: formatter.user_id,
      user_name: formatter.user_name,
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
