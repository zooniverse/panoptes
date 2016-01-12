require "event_stream"

class PublishClassificationEventWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :classification

  def perform(classification_id)
    @classification = Classification.find(classification_id)
    if classification.complete?
      EventStream.push("classification",
        event_id: "classification-#{classification.id}",
        event_time: "#{classification.updated_at}",
        classification_id: classification.id,
        project_id: classification.project.id,
        user_id: classification_user_id,
        _ip_address: classification.user_ip.to_s
      )
    end
  rescue ActiveRecord::RecordNotFound
  end

  private

  def classification_user_id
    user_id = classification.user_id.to_s || classification.user_ip.to_s
    Digest::SHA1.hexdigest(user_id)
  end
end
