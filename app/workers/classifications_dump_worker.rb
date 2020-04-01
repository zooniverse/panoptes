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
      @processor = CsvDumps::DumpProcessor.new(formatter, scope, medium)
      @processor.execute do |formatter|
        # perform our magic of storing the formatted representation
        # use the formatter to inject data into a new export row
        export_row_attributes = ClassificationExportRow.attributes_from_formatter(formatter)
        # TODO: convert the Export row to be a json attributes placeholder
        # and polymorphic resrouce relation to the parent
        # that way it can be reused across subjects etc
        # and if the dump csv format changes
        # we won't have to modify the attributes on the export row
        ClassificationExportRow.create!(export_row_attributes) do |export_row|
          export_row.classification = formatter.classification
        end
        # TODO: optimize the link between and classification -> export row model
        # to ensure we don't have index / table scans on lookup
        # rather just find based on row model PK
      end
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
