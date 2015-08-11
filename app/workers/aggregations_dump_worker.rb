class AggregationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker

  attr_reader :project

  def perform(project_id, medium_id=nil)
    if @project = Project.find(project_id)
      @medium_id = medium_id

      # Set expiry time of signed_url to one day from now
      medium.update!(put_expires: 1.day.from_now.to_i - now.to_i)

      AggregationClient.new.aggregate!(project.id, medium)
    end
  end
end
