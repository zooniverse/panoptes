case Rails.env
when "development", "test"
  # no client
when "staging", "production"
  KinesisPublisher.client = AWS::Kinesis::Client.new
end
