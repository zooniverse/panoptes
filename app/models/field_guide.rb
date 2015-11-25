class FieldGuide < ActiveRecord::Base
  include Linkable
  include RoleControl::ParentalControlled
  include LanguageValidation

  belongs_to :project
  has_many :attached_images, -> { where(type: "field_guide_attached_image") },
    class_name: "Medium", as: :linked

  validates_uniqueness_of :language, case_sensitive: false, scope: :project_id
  validates_presence_of :project

  can_through_parent :project, :update, :index, :show, :destroy

  def items
    super.map(&:with_indifferent_access)
  end
end
