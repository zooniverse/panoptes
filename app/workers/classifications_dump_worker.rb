require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  attr_reader :project

  def perform(project_id, medium_id=nil, obfuscate_private_details=true, date_start=nil, date_end=nil)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
        CSV.open(csv_file_path, 'wb') do |csv|
          dump = ClassificationsDump.new(project, csv,
                                          obfuscate_private_details: obfuscate_private_details,
                                          date_range: date_range(date_start, date_end))
          dump.write
        end
        to_gzip
        write_to_s3
        set_ready_state
        send_email
      ensure
        FileUtils.rm(csv_file_path) rescue nil
        FileUtils.rm(gzip_file_path) rescue nil
      end
    end
  end

  def date_range(a, b)
    if a && b
      a..b
    end
  end
end
