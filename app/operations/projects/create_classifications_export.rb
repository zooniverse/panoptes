module Projects
  class CreateClassificationsExport < Operation
    object :project
    hash :media, strip: false

    def execute
      medium = CreateOrUpdateMedium.run!(inputs.merge(type: :classifications_export))
      ClassificationsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end
  end
end
