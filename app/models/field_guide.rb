class FieldGuide < ActiveRecord::Base
  include Translatable
  include LanguageValidation

  belongs_to :project
  has_many :attached_images, -> { where(type: "field_guide_attached_image") },
    class_name: "Medium", as: :linked

  validates_uniqueness_of :language, case_sensitive: false, scope: :project_id
  validates_presence_of :project

  def self.translatable_attributes
    %i(items)
  end

  # TODO: Add Versioning to this model, and then remove this override
  def latest_version_id
    0
  end

  def items
    super.map(&:with_indifferent_access)
  end
end
