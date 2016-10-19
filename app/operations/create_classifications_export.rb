class CreateClassificationsExport < Operation
  object :object
  import_filters CreateOrUpdateMedium, only: :media

  def execute
    medium = compose(CreateOrUpdateMedium, inputs.merge(type: :classifications_export))
    ClassificationsDumpWorker.perform_async(object.id, object.class.to_s.downcase, medium.id, api_user.id)
    medium
  end
end
