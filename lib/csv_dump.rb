require 'csv'

class CsvDump
  def initialize
    @csv_tempfile = Tempfile.new(['export', '.csv'], mode: File::BINARY)
    @gzip_tempfile = Tempfile.new(['export', '.gz'], mode: File::BINARY)
  end

  def reopen(&block)
    @csv_tempfile.flush
    File.open(csv_file_path, 'rb', &block)
  end

  def <<(row)
    csv << row
  end

  def build_csv(&block)
    yield self
  end

  def gzip!
    @csv_tempfile.flush

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

  def csv
    @csv ||= CSV.new(@csv_tempfile)
  end

  def remove_tempfile(tempfile)
    return unless tempfile
    tempfile.close
    tempfile.unlink
  end
end
