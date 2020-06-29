require 'csv'

class ClassificationsDumpWorker
  include Sidekiq::Worker
  include RateLimitDumpWorker

  sidekiq_options queue: :data_high

  attr_reader :resource, :medium, :scope, :processor

  def perform(resource_id, resource_type, medium_id=nil, requester_id=nil, *args)
    raise ApiErrors::FeatureDisabled unless Panoptes.flipper[:dump_worker_exports].enabled?

    if @resource = CsvDumps::FindsDumpResource.find(resource_type, resource_id)
      @medium = CsvDumps::FindsMedium.new(medium_id, @resource, dump_target).medium
      scope = get_scope(resource)
      @processor = CsvDumps::CachingDumpProcessor.new(formatter, scope, medium) do |formatter|
        # store a formatted representation for re-use in future exports
        # only if not already stored
        unless formatter.cache_resource
          classification = formatter.model
          cached_export = CachedExport.create!(
            resource: classification,
            data: ClassificationExport.hash_format(formatter)
          )
          # link the newly saved classification export to the
          # classification for reuse in future exports
          classification.update_column(:cached_export_id, cached_export.id) # rubocop:disable Rails/SkipsModelValidations
        end
      end
      @processor.execute

      DumpMailer.new(resource, medium, dump_target).send_email
    end
  end

  def formatter
    @formatter ||= Formatter::Csv::Classification.new(cache)
  end

  def get_scope(resource)
    @scope ||= CsvDumps::ClassificationScope.new(resource, cache)
  end

  def cache
    @cache ||= ClassificationDumpCache.new
  end

  def dump_target
    "classifications"
  end
end
