class Medium < ActiveRecord::Base
  class MissingPutFilePath < StandardError; end

  belongs_to :linked, polymorphic: true

  before_validation :create_path, unless: :external_link
  validates :src, presence: true, unless: :external_link
  validates :content_type, presence: true

  before_destroy :queue_medium_removal, unless: :external_link

  ALLOWED_EXPORT_CONTENT_TYPES = %w(text/csv).freeze
  EXPORT_MEDIUM_TYPE_REGEX = /\A(project|workflow)_[a-z_]+_export\z/i

  validate do |medium|
    export_medium = medium.type.match?(EXPORT_MEDIUM_TYPE_REGEX)
    if export_medium && !ALLOWED_EXPORT_CONTENT_TYPES.include?(medium.content_type)
      medium.errors.add(:content_type, "Content-Type must be one of #{ALLOWED_EXPORT_CONTENT_TYPES.join(", ")}")
    end
  end

  def self.inheritance_column
    nil
  end

  def indifferent_attributes
    attributes.dup.with_indifferent_access
  end

  def create_path
    return unless errors.empty?
    self.src ||= MediaStorage.stored_path(content_type, type, *path_opts)
  rescue MediaStorage::UnknownContentType
    self.src ||= nil
  end

  def linked_resource_details
    # field_guide has a _ in it so manually find it vs prefix_*
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

  def queue_medium_removal
    MediumRemovalWorker.perform_async(src)
  end
end
