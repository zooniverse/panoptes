class UrlDownloader
  def self.stream(url)
    Tempfile.create('panoptes-downloaded-file') do |file|
      HTTParty.get(source_url, stream_body: true) do |fragment|
        file.write(fragment)
      end

      file.rewind

      yield file
    end
  end
end
