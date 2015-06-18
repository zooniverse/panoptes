require 'csv'
require 'formatter_csv_classification'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include Formatter::CSV
  include DumpWorker

  attr_reader :project

  def perform(project_id, medium_id=nil, obfuscate_private_details=false)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
        csv_formatter = Formatter::CSV::Classification.new(project, obfuscate_private_details: obfuscate_private_details)
        CSV.open(temp_file_path, 'wb') do |csv|
          csv << Formatter::CSV::Classification.project_headers
          completed_project_classifications.find_each do |classification|
            csv << csv_formatter.to_array(classification)
          end
        end
        write_to_s3
        send_email
      ensure
        FileUtils.rm(temp_file_path)
      end
    end
  end

  def completed_project_classifications
    project.classifications.complete.includes(:user, :workflow)
  end
end
