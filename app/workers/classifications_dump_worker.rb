require 'csv'
require 'formatter_csv_classification'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include Formatter::CSV

  attr_reader :project

  def perform(project_id, show_user_id=false)
    if @project = Project.find(project_id)
      begin
        csv_formatter = Formatter::CSV::Classification.new(project, show_user_id: show_user_id)
        CSV.open(temp_file_path, 'wb') do |csv|
          csv << Formatter::CSV::Classification.project_headers
          completed_project_classifications.find_each do |classification|
            csv << csv_formatter.to_array(classification)
          end
        end
        write_to_s3
        email_owner
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
    project.classifications.complete
  end

  def project_file_path
    [project.owner.display_name, project.display_name]
      .map{ |name_part| name_part.downcase.gsub(/\s/, "_")}
  end

  def medium
    @medium ||= Medium.create(content_type: "text/csv",
                              type: "classifications_export",
                              path_opts: project_file_path,
                              linked: project,
                              private: true)
  end

  def write_to_s3
    medium.put_file(temp_file_path)
  end

  def email_owner
    ClassificationDataMailerWorker.perform_async(@project.id, medium.get_url)
  end
end
