class SubjectSetImportWorker
  include Sidekiq::Worker

  # skip retries for this job to avoid re-running imports with errors
  sidekiq_options retry: 0, queue: :data_medium

  def perform(subject_set_import_id, manifest_row_count)
    subject_set_import = SubjectSetImport.find(subject_set_import_id)
    subject_set_import.import!(manifest_row_count)
    SubjectSetSubjectCounterWorker.new.perform(subject_set_import.subject_set_id)
  end
end
