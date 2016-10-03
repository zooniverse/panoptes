module Projects
  class CreateWorkflowsExport < Operation
    object :object
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :workflows_export))
      WorkflowsDumpWorker.perform_async(object.id, object.class.to_s, medium.id, api_user.id)
      medium
    end
  end
end
