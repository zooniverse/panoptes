class AggregationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker

  attr_reader :project

  def perform(project_id, medium_id)
    if @project = Project.find(project_id)
      @medium_id = medium_id

      # Set expiry time of signed_url to one day from now
      medium.update!(put_expires: 1.day.from_now.to_i - Time.now.to_i)

      AggregationClient.new.aggregate(project, medium)
    end
  end

  def load_medium
    m = Medium.find(@medium_id)
    m.update!(path_opts: project_file_path, private: true, content_type: "application/x-gzip")
    m
  end
end
