# frozen_string_literal: true

class SubjectSetImport < ActiveRecord::Base
  belongs_to :subject_set
  belongs_to :user

  # TODO: move this behaviour to an operation class - out of the model
  def import!(batch_size=500)
    processor = SubjectSetImport::Processor.new(subject_set, user)

    UrlDownloader.stream(source_url) do |io|

      csv_import = SubjectSetImport::CsvImport.new(io)

      # store the number of data lines in our manifest for progress reporting
      update_column(:manifest_count, csv_import.count)

      # import the data in batch_size
      import_batch = csv_import.to_a
      import_batch.in_groups_of(batch_size, false) do |batch|
        subjects_to_import = []
        batch.each do |external_id, attributes|
          subjects_to_import << processor.import(external_id, attributes)
        end
        # build import the subject and associated media resource records
        import_results = Subject.import(subjects_to_import, recursive: true)
        # update the import success and failure values
        save_imported_row_count(import_results.ids.size)
        save_failed_import_rows(import_results.failed_instances)

        # link the imported subjects to the correct subject_set
        set_member_subjects_to_import = import_results.ids.map do |subject_id|
          SetMemberSubject.new(subject_set_id: subject_set.id, subject_id: subject_id, random: rand)
        end
        # and build import the batch
        SetMemberSubject.import(set_member_subjects_to_import, validate: false)
      end
    end
  end

  private

  def save_imported_row_count(imported_row_count)
    return if imported_row_count.zero?

    self.class.where(id: id).update_all("imported_count = imported_count + #{imported_row_count}")
  end

  def save_failed_import_rows(failed_instances)
    failed_import_row_uuids = failed_instances.map(&:external_id)
    failed_import_row_count = failed_import_row_uuids.size
    return if failed_import_row_count.zero?

    update_statements = [
      # increment the failed_count field by num of failures
      "failed_count = failed_count + #{failed_import_row_count}",
      # record the failed external unique identifiers
      'failed_uuids = failed_uuids || array[?]::varchar[]'
    ].join(',')
    self.class.where(id: id).update_all([update_statements, failed_import_row_uuids])
  end
end
