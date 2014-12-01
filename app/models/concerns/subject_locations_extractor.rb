class SubjectLocationsExtractor

  class FormatError < StandardError; end

  def initialize(model, context)
    @model = model
    @context = context
  end

  def locations
    duplicate_locations
    return {} unless @locations
    if migrated_subject?
      migrated_locations
    else
      panoptes_locations
    end
  end

  private

  def duplicate_locations
    @locations = @model.try(:locations).try(:dup)
  end

  def migrated_subject?
    @model.migrated_subject?
  end

  def migrated_locations
    @locations
  end

  def panoptes_locations
    @locations.reduce({}) do |locs, (key, data)|
      path, mime_type = data.values_at("s3_path", "mime_type")
      obj = ::Panoptes.subjects_bucket.objects[path]
      locs[key] = s3_url(obj, mime_type)
      locs
    end
  end

  def s3_url(obj, mime_type)
    if @context[:post_urls]
      obj.url_for(:write, {secure: true,
                           expires_in: 20.minutes.from_now,
                           response_content_type: mime_type,
                           acl: 'public-read'}).to_s
    else
      obj.public_url(secure: true)
    end
  end
end
