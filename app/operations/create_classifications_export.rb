class CreateClassificationsExport < Operation
  object :object
  import_filters CreateOrUpdateMedium, only: :media

  def execute
    medium = compose(CreateOrUpdateMedium, inputs.merge(type: :classifications_export))
    ClassificationsDumpWorker.perform_async(object.id, object.model_name.singular, medium.id, api_user.id)
    medium
  end
end
