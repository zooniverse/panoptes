if ENV["GRAYLOG_URL"].present?
  SemanticLogger.add_appender(
    appender: :graylog,
    url: ENV['GRAYLOG_URL'], # e.g. 'tcp://localhost:12201'

    # If we want to switch from Logstasher to use SemanticLogger for
    # request logs too, remove this filter. Until then this prevents
    # duplicate logging.
    filter: ->(log) { !(log.name =~ /Controller$/ && log.message =~ /^Completed/) }
  )
end
