class FieldGuide < ApplicationRecord
  include Translatable
  include LanguageValidation
  include Versioning

  belongs_to :project
  has_many :attached_images, -> { where(type: "field_guide_attached_image") },
    class_name: "Medium", as: :linked
  has_many :field_guide_versions, dependent: :destroy

  versioned association: :field_guide_versions, attributes: %w(items)

  validates_uniqueness_of :language, case_sensitive: false, scope: :project_id
  validates_presence_of :project

  def self.translatable_attributes
    %i(items)
  end

  def items
    super.map(&:with_indifferent_access)
  end
end
