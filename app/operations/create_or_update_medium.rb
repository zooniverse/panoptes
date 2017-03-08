class CreateOrUpdateMedium < Operation
  object :object
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
    media['metadata']["state"] = 'creating'
    if medium = object.public_send(type)
      medium.update!(media)
      medium.touch
      medium
    else
      object.send("create_#{type}!", media)
    end
  end
end
