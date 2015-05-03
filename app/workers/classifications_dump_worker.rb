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
    "#{Rails.root}/tmp/#{project_file_path}"
  end

  def completed_project_classifications
    project.classifications.where(completed: true)
  end

  def project_file_path
    "#{project.display_name.downcase.gsub(/\s/, "_")}.csv"
  end

  def upload_file_path
    "#{::Panoptes.export_bucket_path}/#{project.id}/#{project_file_path}"
  end

  def s3_object
    @s3_object ||= ::Panoptes.subjects_bucket.objects[upload_file_path]
  end

  def s3_url
    s3_object.url_for(:read, expires: 1.hour.from_now)
  end

  def write_to_s3
    s3_object.write(file: temp_file_path, content_type: "text/csv")
  end

  def email_owner
    ClassificationDataMailerWorker.perform_async(@project.id, s3_url.to_s)
  end
end
