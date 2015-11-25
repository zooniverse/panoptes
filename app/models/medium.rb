class Medium < ActiveRecord::Base
  class MissingPutFilePath < StandardError; end

  belongs_to :linked, polymorphic: true

  before_validation :create_path, unless: :external_link
  validates :src, presence: true, unless: :external_link

  before_destroy :queue_medium_removal

  attr_writer :allow_any_content_type

  ALLOWED_UPLOAD_CONTENT_TYPES = %w(image/jpeg image/png image/gif image/svg+xml)
  ALLOWED_EXPORT_CONTENT_TYPES  = %w(text/csv)
  ALLOWED_AGGREGATION_EXPORT_CONTENT_TYPES = %w(application/x-gzip)

  validate do |medium|
    if !allow_any_content_type && !allowed_content_types.include?(medium.content_type)
      medium.errors.add(:content_type, "Content-Type must be one of #{allowed_content_types.join(", ")}")
    end
  end

  def self.inheritance_column
    nil
  end

  def indifferent_attributes
    attributes.dup.with_indifferent_access
  end

  def create_path
    self.src ||= MediaStorage.stored_path(content_type, type, *path_opts)
  end

  def linked_resource_details
    details = /\A(?<resource>field_guide|[a-z]+)_(?<media_type>\w+)/i.match(type)
    [ details[:resource], details[:media_type] ]
  end

  def pluralize_media_type?(media_type)
    ["attached_image"].include?(media_type)
  end

  # TODO: This method is a good argument for converting this into a STI model
  def location
    resource, media_type = linked_resource_details
    if pluralize_media_type?(media_type)
      "/#{resource.pluralize}/#{linked_id}/#{media_type.pluralize}/#{id}"
    else
      "/#{resource.pluralize}/#{linked_id}/#{media_type}"
    end
  end

  def url_for_format(format)
    case format
    when :put
      put_url
    when :get
      get_url
    else
      ""
    end
  end

  def put_url(opts = {})
    if external_link
      src
    else
      MediaStorage.put_path(src, indifferent_attributes.merge(opts))
    end
  end

  def get_url(opts = {})
    if external_link
      src
    else
      MediaStorage.get_path(src, indifferent_attributes.merge(opts))
    end
  end

  def put_file(file_path, opts={})
    if file_path.blank?
      raise MissingPutFilePath.new("Must specify a file_path to store")
    end
    MediaStorage.put_file(src, file_path, indifferent_attributes.merge(opts))
  end

  private

  def allow_any_content_type
    @allow_any_content_type || false
  end

  def allowed_content_types
    case type
    when "project_aggregations_export"
        ALLOWED_AGGREGATION_EXPORT_CONTENT_TYPES
    when /\Aproject_[a-z_]+_export\z/i
      ALLOWED_EXPORT_CONTENT_TYPES
    else
      ALLOWED_UPLOAD_CONTENT_TYPES
    end
  end

  def queue_medium_removal
    MediumRemovalWorker.perform_async(src)
  end
end
