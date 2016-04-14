module Projects
  class CreateClassificationsExport < Operation
    object :project

    hash :media do
      string :content_type, default: 'text/csv'
      hash :metadata, default: {} do
        array :recipients, default: [] do
          integer
        end
      end
    end

    def execute
      medium = create_or_update_medium(:classifications_export)
      ClassificationsDumpWorker.perform_async(project.id, medium.id, api_user.id)
      medium
    end

    def create_or_update_medium(type, media_create_params=media_params)
      media_create_params['metadata'] ||= { recipients: [api_user.id] }
      if medium = project.public_send(type)
        medium.update!(media_create_params)
        medium.touch
        medium
      else
        media_create_params['metadata']["state"] = 'creating'
        project.send("create_#{type}!", media_create_params)
      end
    end

    def media_params
      @media_params ||= {
        content_type: media[:content_type],
        metadata: media[:metadata]
      }
    end
  end
end
