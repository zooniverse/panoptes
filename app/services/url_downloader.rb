class UrlDownloader
  def self.stream(url)
    Tempfile.create('panoptes-downloaded-file') do |file|
      HTTParty.get(url, stream_body: true) do |fragment|
        file.write(fragment)
      end
      # rewind the file post writing
      file.rewind
      # count the number of lines in the file (including header)
      num_lines = file.each_line.inject(0) { |counter, _line| counter + 1 }
      # rewind post counting lines
      file.rewind

      yield file, num_lines
    end
  end
end
