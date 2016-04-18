module Projects
  class CreateAggregationsExport < Operation
    object :project
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :aggregations_export))
      AggregationsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
