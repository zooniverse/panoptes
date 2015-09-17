require 'csv'

class SubjectsDumpWorker
  include DumpWorker

  attr_reader :project

  def perform(project_id, medium_id=nil)
    if @project = Project.find(project_id)
      @medium_id = medium_id
      begin
        csv_formatter = Formatter::Csv::Subject.new(project)
        CSV.open(csv_file_path, 'wb') do |csv|
          csv << csv_formatter.class.headers
          project_subjects.find_each do |subject|
            csv << csv_formatter.to_array(subject)
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

  def project_subjects
    SetMemberSubject.joins(:subject_set).merge(project.subject_sets)
  end
end
