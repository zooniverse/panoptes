module DumpCommons
  # NEW
  def csv_dump
    @csv_dump ||= CsvDump.new
  end

  def upload_dump
    gzip_file_path = csv_dump.gzip!
    write_to_s3(gzip_file_path)
    yield resource if block_given?
  end

  def cleanup_dump
    csv_dump.cleanup!
  end
end
