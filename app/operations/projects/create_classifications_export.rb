module Projects
  class CreateClassificationsExport < Operation
    object :project
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :classifications_export))
      ClassificationsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
