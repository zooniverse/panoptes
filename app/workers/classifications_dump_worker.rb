require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include DumpWorker
  include DumpMailerWorker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  def formatter
    @formatter ||= Formatter::Csv::Classification.new(cache)
  end

  def get_scope(resource)
    @scope ||= CsvDumps::ClassificationScope.new(resource, cache)
  end

  def cache
    @cache ||= ClassificationDumpCache.new
  end
end
