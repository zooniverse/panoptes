module EventStream
  def self.push(event_type, event_id: SecureRandom.uuid, event_time: Time.now.utc, **metadata)
    event_type = "panoptes.#{event_type}"
    event_id   = "#{event_type}.#{event_id}"
    event_data = metadata.merge(event_id: event_id, event_time: event_time, event_type: event_type).to_json

    MultiKafkaProducer.publish('events', [event_id, event_data])
  end
end
