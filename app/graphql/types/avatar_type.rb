module Types
  class AvatarType < BaseObject
    field :url, String, null: false

    def url
      object.external_link || "//" + object.src
    end
  end
end
