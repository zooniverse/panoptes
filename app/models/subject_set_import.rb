class SubjectSetImport < ActiveRecord::Base

  belongs_to :subject_set
  belongs_to :user

  def import!
    processor = SubjectSetImport::Processor.new(subject_set, user)

    UrlDownloader.stream(source_url) do |io|
      csv_import = SubjectSetImport::CsvImport.new(io)
      csv_import.each do |external_id, attributes|
        processor.import(external_id, attributes)
      end
    end
  end
end
