class Translation < ActiveRecord::Base
  belongs_to :translated, polymorphic: true, required: true
  validate :validate_strings

  # Look at adding in paper trail change tracking for laguage / strings here

  private

  def validate_strings
    unless strings.is_a?(Hash)
      errors.add(:strings, "must be present but can be empty")
    end
  end
end
