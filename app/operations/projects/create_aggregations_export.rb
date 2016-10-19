module Projects
  class CreateAggregationsExport < Operation
    object :object
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :aggregations_export))
      AggregationsDumpWorker.perform_async(object.id, object.class.to_s.downcase, medium.id, api_user.id)
      medium
    end
  end
end
