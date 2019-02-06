class Translation < ActiveRecord::Base
  belongs_to :translated, polymorphic: true, required: true

  validate :validate_translated_is_translatable
  validate :validate_strings
  validates_presence_of :language
  validate :validate_string_versions
  validates_uniqueness_of :language,
    scope: %i(translated_type translated_id),
    message: "translation already exists for this resource"

  before_validation :downcase_language, on: :create

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

  def update_strings_and_versions(new_strings, version_number)
    old_strings = self.strings.stringify_keys
    new_strings = new_strings.stringify_keys

    Translations::Strings.compare(old_strings, new_strings) do |change, key|
      case change
      when :added, :changed
        strings[key] = new_strings[key]
        string_versions[key] = version_number
      when :removed
        strings.delete(key)
        string_versions.delete(key)
      end
    end
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

  def validate_string_versions
    unless string_versions.is_a?(Hash)
      errors.add(:string_versions, "must be present but can be empty")
      return
    end

    # Next we need to validate that all of the specified IDs in this attribute are
    # actually IDs that belong to the translated resource.

    return unless translated.present? # This is a different validation error

    known_version_ids = translated.version_ids
    referenced_version_ids = string_versions.values.uniq
    unknown_version_ids = referenced_version_ids - known_version_ids

    if unknown_version_ids.present?
      errors.add(:string_versions, "references unknown versions: #{unknown_version_ids.join(", ")}")
    end
  end

  def downcase_language
    if language
      self.language = language.downcase
    end
  end
end
