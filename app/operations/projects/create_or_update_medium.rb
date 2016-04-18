module Projects
  class CreateOrUpdateMedium < Operation
    object :project
    symbol :type

    hash :media do
      string :content_type, default: 'text/csv'
      hash :metadata, default: {} do
        array :recipients, default: -> { [api_user.id] } do
          integer
        end
      end
    end

    def execute
      if medium = project.public_send(type)
        medium.update!(media)
        medium.touch
        medium
      else
        media['metadata']["state"] = 'creating'
        project.send("create_#{type}!", media)
      end
    end
  end
end
