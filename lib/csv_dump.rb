class CsvDump
  def self.open(&block)
    csv_dump = new
    csv_dump.build_csv(&block)
    csv_dump
  end

  def initialize
    @csv_tempfile = Tempfile.new(['export', '.csv'])
    @gzip_tempfile = Tempfile.new(['export', '.gz'])
  end

  def build_csv(&block)
    CSV.open(csv_file_path, 'wb', &block)
  end

  def gzip!
    Zlib::GzipWriter.open(gzip_file_path) do |gz|
      gz.mtime = File.mtime(csv_file_path)
      gz.orig_name = File.basename(csv_file_path)
      File.open(csv_file_path) do |fp|
        while chunk = fp.read(16 * 1024) do
          gz.write(chunk)
        end
      end
      gz.close
    end
  end

  def cleanup!
    remove_tempfile(@csv_tempfile)
    remove_tempfile(@gzip_tempfile)
  end

  def csv_file_path
    @csv_tempfile.path
  end

  def gzip_file_path
    @gzip_tempfile.path
  end

  private

  def remove_tempfile(tempfile)
    return unless tempfile
    tempfile.close
    tempfile.unlink
  end
end
