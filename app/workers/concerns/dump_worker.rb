module DumpWorker
  extend ActiveSupport::Concern

  def dump_target
    @dump_target ||= self.class.to_s.underscore.split("_")[0]
  end

  def dump_type
    "project_#{dump_target}_export"
  end

  def mailer
    "#{dump_target.singularize}_data_mailer_worker".camelize.constantize
  end

  def temp_file_path
    "#{Rails.root}/tmp/#{project_file_path.join("_")}.csv"
  end

  def project_file_path
    [dump_type, project.owner.login, project.display_name]
      .map{ |name_part| name_part.downcase.gsub(/\s/, "_")}
  end

  def medium
    @medium ||= @medium_id ? load_medium : create_medium
  end

  def create_medium
    Medium.create!(content_type: "text/csv",
                   type: dump_type,
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
    mailer.perform_async(@project.id, medium.get_url, emails)
  end
end
