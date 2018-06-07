require 'csv'

class SubjectSetImport::CsvImport
  def initialize(io)
    @io = io
  end

  def each
    return Enumerator.new(self) unless block_given?

    csv = CSV.new(@io, headers: true)

    csv.each do |row|
      uuid = row["uuid"]
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

      yield uuid, build_attributes(locations, metadata)
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
