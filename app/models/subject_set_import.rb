# frozen_string_literal: true

class SubjectSetImport < ActiveRecord::Base
  belongs_to :subject_set
  belongs_to :user

  def import!(update_progress_every_rows=500)
    processor = SubjectSetImport::Processor.new(subject_set, user)

    UrlDownloader.stream(source_url) do |io|
      csv_import = SubjectSetImport::CsvImport.new(io)

      imported_row_count = 0

      csv_import.each do |external_id, attributes|
        begin
          processor.import(external_id, attributes)
        rescue SubjectSetImport::Processor::FailedImport
          update_columns(
            # increment the failed_count field
            failed_count: failed_count + 1,
            # log the failed external unique identifier
            failed_uuids: failed_uuids | [external_id]
          )
        end

        imported_row_count += 1

        # update the imported_count as we progress through the import
        # so we can use this as a progress metric on API resource polling
        save_imported_row_count(imported_row_count) if (imported_row_count % update_progress_every_rows).zero?
      end

      # finish reporting the number of imported records
      save_imported_row_count(imported_row_count)
    end
  end

  private

  def save_imported_row_count(imported_row_count)
    update_column(:imported_count, imported_row_count)
  end
end
