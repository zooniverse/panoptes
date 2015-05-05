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
        m[mime_type] = s3_url(path, mime_type)
        m
      end
    end
  end

  def s3_url(path, mime_type)
    if @context[:post_urls]
   else
      "https://#{path}"
    end
  end
end
