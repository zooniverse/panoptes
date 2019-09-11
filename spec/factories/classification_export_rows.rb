FactoryBot.define do
  factory :classification_export_row do
    transient do
      classification { nil }
    end

    after(:build) do |row, env|
      c = env.classification || create(:classification)
      cache = ClassificationDumpCache.new
      cache.reset_classification_subjects(
        c.subject_ids.map { |s_id| [ c.id, s_id ] }
      )
      cache.reset_subjects(c.subjects)
      formatter = Formatter::Csv::Classification.new(cache)
      formatter.classification = c

      row.classification = c
      row.project_id = formatter.project_id
      row.workflow_id = formatter.workflow_id
      row.user_id = formatter.user_id
      row.user_name = formatter.user_name
      # TODO: remove / make this consistent
      row.user_ip = nil
      row.workflow_name = formatter.workflow_name
      row.workflow_version = formatter.workflow_version
      row.classification_created_at = formatter.created_at
      row.gold_standard = formatter.gold_standard
      row.expert = formatter.expert
      row.metadata = formatter.metadata
      row.annotations = formatter.annotations
      row.subject_data = formatter.subject_data
      row.subject_ids = formatter.subject_ids
    end
  end
end
