class UrlDownloader
  class Failed < StandardError; end
  def self.stream(url)
    Tempfile.create('panoptes-downloaded-file') do |file|
      HTTParty.get(url, stream_body: true) do |fragment|
        # follow redirects and keep processing
        next if [301, 302].include?(fragment.code)

        # any other failure modes we raise, e.g. 404
        raise Failed, "#{fragment.code} - Failed to download URL: #{url}" unless fragment.code == 200

        # 200 on fetch so we can copy the remote content to the file
        file.write(fragment)
      end

      # rewind the file post writing for new reads
      file.rewind

      yield file
    end
  end
end
