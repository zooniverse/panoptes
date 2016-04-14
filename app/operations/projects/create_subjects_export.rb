module Projects
  class CreateSubjectsExport < Operation
    object :project
    hash :media, strip: false

    def execute
      medium = CreateOrUpdateMedium.run!(inputs.merge(type: :subjects_export))
      SubjectsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
