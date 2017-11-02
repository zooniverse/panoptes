class ClassificationExportRow < ActiveRecord::Base
  belongs_to :classification, required: true
  belongs_to :project, required: true
  belongs_to :workflow, required: true
  belongs_to :user

  validates_presence_of :workflow_name, :workflow_version,
      :classification_created_at, :metadata, :annotations,
      :subject_data, :subject_ids

  def self.create_from_classification(classification)
    # TODO: look at removing the cache object here as
    # the formatter doesn't need the cache for a single resource,
    cache = ClassificationDumpCache.new
    cache.reset_classification_subjects(
      classification.subject_ids.map { |s_id| [ classification.id, s_id ] }
    )
    cache.reset_subjects(classification.subjects)

    formatter = Formatter::Csv::Classification.new(cache)
    formatter.classification = classification

    attributes = attributes_from_csv_formatter(formatter)
    create!(attributes.merge(classification: classification))
  end

  def self.attributes_from_csv_formatter(formatter)
    {
      project_id: formatter.project_id,
      workflow_id: formatter.workflow_id,
      user_id: formatter.user_id,
      user_name: formatter.user_name,
      # TODO: make this consistent across runs
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
