require 'csv'

class SubjectSetImport::CsvImport
  attr_reader :csv

  def initialize(io)
    @csv = CSV.new(io, headers: true)
  end

  def headers
    csv.headers
  end

  def each
    return Enumerator.new(self) unless block_given?

    csv.each do |row|
      external_id = row['external_id']
      locations = []
      metadata = {}

      row.each do |header, value|
        type, key = extract_header(header)

        case type
        when 'location'
          mime_type = mime_type_from_file_extension(value)
          locations << {mime_type => value}
        when 'metadata'
          metadata[key] = value
        end
      end

      yield external_id, build_attributes(locations, metadata)
    end
  end

  private

  def extract_header(header)
    header.split(':')
  end

  def build_attributes(locations, metadata)
    {locations: locations, metadata: metadata}
  end

  def mime_type_from_file_extension(url)
    extension = File.extname(url).sub(/\A\./, '')
    Mime::Type.lookup_by_extension(extension).to_s
  end
end
