module CsvDumps
  class SubjectScope < DumpScope
    attr_reader :cache, :project_workflow_ids

    def initialize(resource, cache=nil)
      super(resource)
      @cache = cache
      @project_workflow_ids = resource.workflows.pluck(:id)
    end

    def each
      read_from_database do
        ActiveRecord::Base.uncached do
          # Use batch iteration to allow prefetching per batch
          project_subjects.find_in_batches do |batch|
            cache&.reset_for_batch(batch, project_workflow_ids)
            batch.each { |subject| yield subject }
          end
        end
      end
    end

    private

    def project_subjects
      Subject
        .joins(:subject_sets)
        .eager_load(:subject_sets, :locations)
        .merge(resource.subject_sets)
    end
  end
end
