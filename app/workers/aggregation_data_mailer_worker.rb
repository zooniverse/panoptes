class AggregationDataMailerWorker
  include Sidekiq::Worker
  include DumpMailerWorker

  attr_reader :medium

  def perform(media_id)
    @medium = Medium.find(media_id)
    AggregationDataMailer.aggregation_data(project, media_get_url, emails).deliver
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def project
    medium.linked
  end
end
