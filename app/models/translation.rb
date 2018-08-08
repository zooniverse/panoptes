class Translation < ActiveRecord::Base
  belongs_to :translated, polymorphic: true, required: true
  validate :validate_translated_is_translatable
  validate :validate_strings
  validates_presence_of :language

  before_validation :downcase_language, on: :create

  validates_uniqueness_of :language,
    scope: %i(translated_type translated_id),
    message: "translation already exists for this resource"

  # TODO: Versioning and maintaining a live, published version

  def self.translated_model_names
    @translated_model_names ||= %w(
      project
      project_page
      organization
      organization_page
      field_guide
      tutorial
      workflow
    ).freeze
  end

  private

  def validate_strings
    unless strings.is_a?(Hash)
      errors.add(:strings, "must be present but can be empty")
    end
  end

  def validate_translated_is_translatable
    unless translated.is_a?(Translatable)
      errors.add(:translated, "must be a translatable model")
    end
  end

  def downcase_language
    if language
      self.language = language.downcase
    end
  end
end
