module Projects
  class CreateWorkflowsExport < Operation
    object :project
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :workflows_export))
      WorkflowsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
