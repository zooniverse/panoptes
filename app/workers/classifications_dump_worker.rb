require 'csv'
require 'formatter_csv_classification'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include Formatter::CSV

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

  private

  def temp_file_path
    "#{Rails.root}/tmp/#{project_file_path.join("_")}.csv"
  end

  def completed_project_classifications
    project.classifications.complete.includes(:user)
  end

  def project_file_path
    [project.owner.login, project.display_name]
      .map{ |name_part| name_part.downcase.gsub(/\s/, "_")}
  end

  def medium
    @medium ||= @medium_id ? load_medium : create_medium
  end

  def create_medium
    Medium.create!(content_type: "text/csv",
                   type: "project_classifications_export",
                   path_opts: project_file_path,
                   linked: project,
                   private: true)
  end

  def load_medium
    m = Medium.find(@medium_id)
    m.update!(path_opts: project_file_path, private: true)
    m
  end

  def write_to_s3
    medium.put_file(temp_file_path)
  end

  def emails
    if recipients = medium.try(:metadata).try(:[], "recipients")
      User.where(id: recipients).pluck(:email)
    else
      [project.owner.email]
    end
  end

  def send_email
    ClassificationDataMailerWorker.perform_async(@project.id, medium.get_url, emails)
  end
end
