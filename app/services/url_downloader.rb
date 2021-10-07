class UrlDownloader
  def self.stream(url)
    Tempfile.create('panoptes-downloaded-file') do |file|
      HTTParty.get(url, stream_body: true) do |fragment|
        file.write(fragment)
      end
      # rewind the file post writing for new reads
      file.rewind

      yield file
    end
  end
end
