case Rails.env
when "development", "test"
  # no client
when "staging", "production"
  EventStream.client = AWS::Kinesis::Client.new
end
