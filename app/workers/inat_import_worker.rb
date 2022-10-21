# frozen_string_literal: true

class InatImportWorker
  include Sidekiq::Worker

  # skip retries for this job to avoid re-running imports with errors
  sidekiq_options retry: 0, queue: :data_medium

  def perform(user_id, taxon_id, subject_set_id, updated_since=nil)
    inat = Inaturalist::ApiInterface.new(taxon_id: taxon_id, updated_since: updated_since)
    importer = Inaturalist::SubjectImporter.new(user_id, subject_set_id)

    # Use a SubjectSetImport instance to track progress & store data
    ss_import = importer.subject_set_import

    failed_imports = []
    imported_row_count = 0
    inat.observations.each do |obs|
      begin
        importer.import(obs)
      rescue SubjectSetImport::Processor::FailedImport
        ss_import.update_columns( failed_count: failed_count + 1, failed_uuids: failed_uuids | [external_id])
      end

      imported_row_count += 1

      # update the imported_count as we progress through the import so we can use
      # this as a progress metric on API resource polling (see SubjectSetWorker)
      save_imported_row_count(imported_row_count) if (imported_row_count % update_progress_every_rows(inat.total_results)).zero?
    end

    ss_import.save_imported_row_count(imported_row_count)

    # Count that subject set, like right now
    SubjectSetSubjectCounterWorker.new.perform(subject_set_id)

    # notify the user about the import success / failure
    InatImportCompletedMailerWorker.perform_async(ss_import.id)
  end

  def update_progress_every_rows(total_results)
    update_progress_every_rows ||= SubjectSetImport::ProgressUpdateCadence.calculate(total_results)
  end
end
