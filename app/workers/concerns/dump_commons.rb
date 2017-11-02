module DumpCommons
  # NEW
  def csv_dump
    @csv_dump ||= CsvDump.new
  end

  def upload_dump
    csv_dump.gzip!
    write_to_s3
    yield resource if block_given?
  end

  def cleanup_dump
    csv_dump.cleanup!
  end
end
