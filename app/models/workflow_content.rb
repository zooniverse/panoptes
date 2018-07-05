class WorkflowContent < ActiveRecord::Base
  include TranslatedContent
  include CacheModelVersion

  validates_presence_of :language
  validate :validate_strings

  private

  def validate_strings
    unless strings.is_a?(Hash)
      errors.add(:strings, "must be present but can be empty")
    end
  end
end
