# frozen_string_literal: true

class Medium < ApplicationRecord
  class MissingPutFilePath < StandardError; end

  belongs_to :linked, polymorphic: true

  before_validation :create_path, unless: :external_link
  validates :src, presence: true, unless: :external_link
  validates :content_type, presence: true

  before_destroy :queue_medium_removal, unless: :external_link

  ALLOWED_EXPORT_CONTENT_TYPES = %w(text/csv).freeze
  # We use an allow list to validate file types to keep consistent with UI file validation code
  # See for client file validation: https://github.com/zooniverse/Panoptes-Front-End/blob/master/app/lib/put-file.js
  ALLOWED_CONTENT_TYPES = {
    'application/json': 1,
    'application/pdf': 2,
    'audio/aac': 3,
    'audio/midi': 4,
    'audio/x-midi': 5,
    'audio/mp3': 6,
    'audio/mp4': 7,
    'audio/x-m4a': 8,
    'audio/mpeg': 9,
    'audio/wav': 10,
    'image/jpeg': 11,
    'image/gif': 12,
    'image/png': 13,
    'image/tiff': 14,
    'image/x-icon': 15,
    'image/svg+xml': 16,
    'text/csv': 17,
    'text/plain': 18,
    'video/mp4': 19,
    'video/mpeg': 20
}.freeze

  EXPORT_MEDIUM_TYPE_REGEX = /\A(project|workflow)_[a-z_]+_export\z/i

  validate :validate_content_type
  validate :validate_export_content_type, if: :export_medium

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
    details = /\A(?<resource>field_guide|subject_set|[a-z]+)_(?<media_type>\w+)/i.match(type)
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
    raise MissingPutFilePath, 'Must specify a file_path to store' if file_path.blank?

    MediaStorage.put_file(src, file_path, indifferent_attributes.merge(opts))
  end

  def put_file_with_retry(file_path, opts={}, num_retries=5)
    attempts ||= 1
    put_file(file_path, opts)
  rescue MissingPutFilePath => e # do not retry these invalid put_file args
    raise e
  rescue => e # rubocop:disable Style/RescueStandardError
    retry if (attempts += 1) <= num_retries

    # ensure we raise unexpected errors once we've exhausted
    # the number of retries to continute to surface these errors
    raise e
  end

  def export_medium
    type.match?(EXPORT_MEDIUM_TYPE_REGEX)
  end

  def validate_content_type
    errors.add(:content_type, "Invalid file type. Content-Type must be one of the following: #{ALLOWED_CONTENT_TYPES.keys.join(', ')}") unless ALLOWED_CONTENT_TYPES.with_indifferent_access.key?(content_type)
  end

  def validate_export_content_type
    errors.add(:content_type, "Content-Type for exports must be one of #{ALLOWED_EXPORT_CONTENT_TYPES.join(", ")}") unless ALLOWED_EXPORT_CONTENT_TYPES.include?(content_type)
  end

  private

  def queue_medium_removal
    MediumRemovalWorker.perform_async(src, indifferent_attributes)
  end
end
