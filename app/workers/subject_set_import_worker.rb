class SubjectSetImportWorker
  include Sidekiq::Worker

  def perform(subject_set_import_id)
    subject_set_import = SubjectSetImport.find(subject_set_import_id)
    subject_set_import.import!
  end
end
