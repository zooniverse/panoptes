class Medium < ActiveRecord::Base
  belongs_to :linked, polymorphic: true

  before_save :create_path, unless: :external_link

  def self.inheritance_column
    nil
  end

  ALLOWED_UPLOAD_CONTENT_TYPES = %w(image/jpeg image/png image/gif)
  ALLOWED_EXPORT_CONTENT_TYPES  = %w(text/csv)

  validate do |medium|
    unless allowed_content_types.include?(medium.content_type)
      medium.errors.add(:content_type, "Content-Type must be one of #{allowed_content_types.join(", ")}")
    end
  end

  def indifferent_attributes
    attributes.dup.with_indifferent_access
  end

  def create_path
    self.src ||= MediaStorage.stored_path(content_type, type, *path_opts)
  end

  def put_url
    if external_link
      src
    else
      MediaStorage.put_path(src, indifferent_attributes)
    end
  end

  def get_url
    if external_link
      src
    else
      MediaStorage.get_path(src, indifferent_attributes)
    end
  end

  def put_file(file_path)
    MediaStorage.put_file(src, file_path, indifferent_attributes)
  end

  def allowed_content_types
    if type == "classifications_export"
      ALLOWED_EXPORT_CONTENT_TYPES
    else
      ALLOWED_UPLOAD_CONTENT_TYPES
    end
  end
end
