class SubjectSerializer
  include RestPack::Serializer
  attributes :id, :metadata, :locations, :zooniverse_id, :created_at, :updated_at
  can_include :owner, :versions

  def locations
    locations = @model.try(:locations).try(:dup)
    return {} unless locations
    locations.reduce({}) do |locs, (key, data)|
      path, mime = data.values_at("s3_path", "mime_type")
      obj = ::Panoptes.subjects_bucket.objects[path]
      locs[key] = if @context[:post_urls]
                    obj.url_for(:write, {secure: true,
                                         expires_in: 20.minutes.from_now,
                                         response_content_type: mime,
                                         acl: 'public-read'}).to_s
                  else
                    obj.public_url(secure: true)
                  end
      locs
    end
  end
end
