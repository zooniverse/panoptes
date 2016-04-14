module Projects
  class CreateSubjectsExport < Operation
    object :project
    import_filters CreateOrUpdateMedium, only: :media

    def execute
      medium = compose(CreateOrUpdateMedium, inputs.merge(type: :subjects_export))
      SubjectsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
