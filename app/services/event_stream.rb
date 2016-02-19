module EventStream
  # Publishes an event on the Kinesis stream
  #
  # @param event [String] the event type
  # @param data [Hash] the event data
  # @param linked [Hash] related models to the data
  # @param shard_by [String] if present, reader order will be guaranteed within this shard. If left blank, the entire stream will always be a single shard.
  def self.publish(event:, data:, linked: {}, shard_by: nil)
    return unless configured?

    client.put_record(
      stream_name: stream_name,
      partition_key: (shard_by || event).to_s,
      data: format_data(event, data, linked)
    )
  rescue StandardError => ex
    # While we're still evaluating Kinesis, don't propagate this error, but do notify Honeybadger.
    Honeybadger.notify(ex)
  end

  def self.format_data(event, data, linked)
    {
      source: 'panoptes',
      type: event,
      version: '1.0.0',
      timestamp: Time.now.utc.iso8601,
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
    ENV['KINESIS_STREAM']
  end

  def self.configured?
    stream_name.present? && client.present?
  end
end
