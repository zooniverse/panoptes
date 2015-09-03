require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker

  attr_reader :project

  def perform(project_id, medium_id=nil, obfuscate_private_details=true)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
        csv_formatter = Formatter::Csv::Classification.new(project, obfuscate_private_details: obfuscate_private_details)
        CSV.open(csv_file_path, 'wb') do |csv|
          csv << csv_formatter.class.headers
          completed_project_classifications.find_each do |classification|
            csv << csv_formatter.to_array(classification)
          end
        end
        to_gzip
        write_to_s3
        set_ready_state
        send_email
      ensure
        FileUtils.rm(csv_file_path)
        FileUtils.rm(gzip_file_path)
      end
    end
  end

  def completed_project_classifications
    project.classifications
    .complete
    .joins(:workflow)
    .includes(:user, workflow: [:workflow_contents])
  end
end
