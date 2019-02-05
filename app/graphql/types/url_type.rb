module Types
  class UrlType < BaseObject
    field :url, String, null: false
    field :path, String, null: true
    field :site, String, null: true
    field :label, String, null: true
  end
end
