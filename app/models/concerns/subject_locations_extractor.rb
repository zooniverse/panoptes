class SubjectLocationsExtractor

  class FormatError < StandardError; end

  def initialize(model, context)
    @model = model
    @context = context
  end

  def locations
    duplicate_locations
    return [] unless @locations
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
    @locations.map do |media|
      media.reduce({}) do |m, (mime_type, path)|
        obj = ::Panoptes.subjects_bucket.objects[path]
        m[mime_type] = s3_url(obj, mime_type)
        m
      end
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
