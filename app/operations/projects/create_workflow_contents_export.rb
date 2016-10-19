module Projects
  class CreateWorkflowContentsExport < Operation
    object :object
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :workflow_contents_export))
      WorkflowContentsDumpWorker.perform_async(object.id, object.class.to_s.downcase, medium.id, api_user.id)
      medium
    end
  end
end
