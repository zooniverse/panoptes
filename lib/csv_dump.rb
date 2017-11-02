require 'csv'

class CsvDump
  def initialize
    @csv_tempfile = Tempfile.new(['export', '.csv'], mode: File::BINARY)
    @gzip_tempfile = Tempfile.new(['export', '.gz'], mode: File::BINARY)
  end

  def reopen(&block)
    @csv_tempfile.flush
    File.open(@csv_tempfile.path, 'rb', &block)
  end

  def <<(row)
    csv << row
  end

  def gzip!
    Zlib::GzipWriter.open(@gzip_tempfile.path) do |gz|
      gz.mtime = @csv_tempfile
      gz.orig_name = File.basename(@csv_tempfile.path)

      reopen do |fp|
        while chunk = fp.read(16 * 1024) do
          gz.write(chunk)
        end
      end
      gz.close
    end

    @gzip_tempfile.path
  end

  def cleanup!
    remove_tempfile(@csv_tempfile)
    remove_tempfile(@gzip_tempfile)
  end

  private

  def csv
    @csv ||= CSV.new(@csv_tempfile)
  end

  def remove_tempfile(tempfile)
    return unless tempfile
    tempfile.close
    tempfile.unlink
  end
end
