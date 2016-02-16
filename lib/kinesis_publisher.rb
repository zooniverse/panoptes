class KinesisPublisher
  def self.publish(event_type, partition_key, data, linked = {})
    return unless client

    client.put_record(
      stream_name: stream_name,
      partition_key: partition_key.to_s,
      data: format_data(event_type, data, linked)
    )
  rescue StandardError => ex
    # While we're still evaluating Kinesis, don't propagate this error, but do notify Honeybadger.
    Honeybadger.notify(ex)
  end

  def self.format_data(event_type, data, linked)
    {
      source: 'panoptes',
      type: event_type,
      version: '1.0.0',
      data: data,
      linked: linked
    }.to_json
  end

  def self.client
    @client
  end

  def self.client=(client)
    @client = client
  end

  def self.stream_name
    ENV.fetch('KINESIS_STREAM') { "panoptes-#{Rails.env}" }
  end
end
