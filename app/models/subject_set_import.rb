# frozen_string_literal: true

class SubjectSetImport < ActiveRecord::Base
  belongs_to :subject_set
  belongs_to :user

  def import!(manifest_row_count)
    update_progress_every_rows = ProgressUpdateCadence.calculate(manifest_row_count)
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
    self.imported_count = imported_row_count
    save! # ensure we touch updated_at for busting any serializer cache
  end

  class ProgressUpdateCadence
    def self.calculate(manifest_row_count)
      return 0 if manifest_row_count.zero?

      # manifest row count can be 10000 or more (see ENV['SUBJECT_SET_IMPORT_MANIFEST_ROW_LIMIT'])
      # thus we want to offset the value being used to calculate the
      # order of magnitude to fit our desired ranges
      manifest_row_count -= 1 if manifest_row_count > 1

      order_of_magnitude = Math.log10(manifest_row_count).floor
      case order_of_magnitude
      when 0
        5   # num rows 1 to 10 - update up to two times
      when 1
        25  # num rows 11 to 100 - update up to 4 times
      when 2
        50  # num rows 101 to 1000 - update up to 20 times
      when 3
        250 # num rows 1001 to 10000 - update up to 40 times
      else
        500 # fallback for any really large imports, avoid lots of updates
      end
    end
  end
end
