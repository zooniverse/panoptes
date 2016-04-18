module Projects
  class CreateWorkflowContentsExport < Operation
    object :project
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :workflow_contents_export))
      WorkflowContentsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
