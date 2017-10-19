class Export < ActiveRecord::Base
  belongs_to :exportable, polymorphic: true, required: true

  validate :validate_data

  private

  def validate_data
    unless data.is_a?(Hash)
      errors.add(:data, "must be present but can be empty")
    end
  end
end
