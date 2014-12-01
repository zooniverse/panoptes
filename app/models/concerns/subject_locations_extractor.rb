class SubjectLocationsExtractor

  class FormatError < StandardError; end

  def initialize(locations, context)
    @locations = locations
    @context = context
  end

  def locations
    if migrated_project_format?
      migrated_project_locations
    else
      panoptes_locations
    end
  end

  private

  def migrated_project_format?
    !!@locations.values.first.is_a?(String)
  end

  def migrated_project_locations
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
