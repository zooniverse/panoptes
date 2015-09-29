module DumpWorker
  extend ActiveSupport::Concern

  included do
    include Sidekiq::Worker
  end

  def dump_target
    @dump_target ||= self.class.to_s.underscore.match(/\A(\w+)_dump_worker\z/)[1]
  end

  def dump_type
    "project_#{dump_target}_export"
  end

  def mailer
    "#{dump_target.singularize}_data_mailer_worker".camelize.constantize
  end

  def temp_file_path
    "#{Rails.root}/tmp/#{project_file_path.join("_")}"
  end

  def csv_file_path
    "#{Rails.root}/tmp/#{project_file_path.join("_")}.csv"
  end

  def gzip_file_path
    "#{Rails.root}/tmp/#{project_file_path.join("_")}.gz"
  end

  def project_file_path
    [dump_type, project.owner.login, project.display_name]
      .map{ |name_part| name_part.downcase.gsub(/\s/, "_")}
  end

  def medium
    @medium ||= @medium_id ? load_medium : create_medium
  end

  def set_ready_state
    medium.metadata["state"] = 'ready'
    medium.save!
  end

  def create_medium
    Medium.create!(content_type: "text/csv",
                   type: dump_type,
                   path_opts: project_file_path,
                   linked: project,
                   metadata: { state: 'creating' },
                   private: true)
  end

  def load_medium
    m = Medium.find(@medium_id)
    m.update!(path_opts: project_file_path, private: true, content_type: "text/csv")
    m
  end

  def write_to_s3
    medium.put_file(gzip_file_path, compressed: true)
  end

  def emails
    if recipients = medium.try(:metadata).try(:[], "recipients")
      User.where(id: recipients).pluck(:email)
    else
      [project.owner.email]
    end
  end

  def send_email
    mailer.perform_async(@project.id, media_get_url, emails)
  end

  def media_get_url(expires=24*60)
    medium.get_url(get_expires: expires)
  end

  def to_gzip
    Zlib::GzipWriter.open(gzip_file_path) do |gz|
      gz.mtime = File.mtime(csv_file_path)
      gz.orig_name = File.basename(csv_file_path)
      gz.write IO.binread(csv_file_path)
      gz.close
    end
  end
end
