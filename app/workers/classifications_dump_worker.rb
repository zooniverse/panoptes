require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  attr_reader :project

  def perform(project_id, medium_id=nil, obfuscate_private_details=true)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
        CSV.open(csv_file_path, 'wb') do |csv|
          dump = ClassificationsDump.new(project, obfuscate_private_details: obfuscate_private_details)
          dump.write_to(csv)
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
end
