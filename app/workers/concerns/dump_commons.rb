module DumpCommons
  def csv_file_path
    @csv_tempfile ||= Tempfile.new(['export', '.csv'])
    @csv_tempfile.path
  end

  def gzip_file_path
    @gzip_tempfile ||= Tempfile.new(['export', '.gz'])
    @gzip_tempfile.path
  end

  def upload_dump
    to_gzip
    write_to_s3
    yield resource if block_given?
  end

  def to_gzip
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

  def cleanup_dump
    remove_tempfile(@csv_tempfile)
    remove_tempfile(@gzip_tempfile)
  end

  def remove_tempfile(tempfile)
    return unless tempfile
    tempfile.close
    tempfile.unlink
  end
end
