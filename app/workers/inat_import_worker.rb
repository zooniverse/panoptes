# frozen_string_literal: true

class InatImportWorker
  include Sidekiq::Worker

  # skip retries for this job to avoid re-running imports with errors
  sidekiq_options retry: 0, queue: :dumpworker
  sidekiq_options lock: :until_and_while_executing

  def perform(user_id, taxon_id, subject_set_id, updated_since=nil)
    @inat = Inaturalist::ApiInterface.new(taxon_id: taxon_id, updated_since: updated_since)
    @importer = Inaturalist::SubjectImporter.new(user_id, subject_set_id)

    @imported_row_count = 0
    subjects_to_import = []

    @inat.observations.each_with_index do |obs, i|
      subjects_to_import << @importer.to_subject(obs)
      next unless process_batch?(i)

      subject_import_results = @importer.import_subjects(subjects_to_import)
      new_smses = @importer.build_smses(subject_import_results)
      @importer.import_smses(new_smses)

      # Record import state
      save_status(subject_import_results)

      # Assist ruby GC wherever possible
      subjects_to_import = []
      import_results, new_smses, subject_import_results = nil
    end

    # Count that subject set, like right now
    SubjectSetSubjectCounterWorker.new.perform(subject_set_id)

    # notify the user about the import success / failure
    InatImportCompletedMailerWorker.perform_async(ss_import.id)
  end

  def import_batch_size
    ENV.fetch('INAT_IMPORT_BATCH_SIZE', 200)
  end

  def process_batch?(index)
    (index % import_batch_size).zero? && index.positive?
  end

  def ss_import
    @ss_import ||= @importer.subject_set_import
  end

  def save_status(import_results)
    @imported_row_count += import_results.ids.size
    ss_import.save_imported_row_count(@imported_row_count)
    save_failed_import_rows(import_results.failed_instances) if import_results.failed_instances
  end

  def update_progress_every_rows(total_results)
    SubjectSetImport::ProgressUpdateCadence.calculate(total_results)
  end

  def save_failed_import_rows(failed_instances)
    failed_import_row_uuids = failed_instances.map(&:external_id)
    failed_import_row_count = failed_import_row_uuids.size
    return if failed_import_row_count.zero?

    ss_import.update_columns(
      failed_count: ss_import.failed_count + failed_import_row_count,
      failed_uuids: ss_import.failed_uuids | failed_import_row_uuids
    )
  end
end
