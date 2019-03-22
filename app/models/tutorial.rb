class Tutorial < ActiveRecord::Base
  include Translatable
  include Versioning

  belongs_to :project
  has_many :workflow_tutorials
  has_many :workflows, through: :workflow_tutorials
  has_many :attached_images, -> { where(type: "tutorial_attached_image") }, class_name: "Medium",
    as: :linked
  has_many :tutorial_versions, dependent: :destroy

  versioned association: :tutorial_versions, attributes: %w(steps kind display_name)

  validates_presence_of :project

  def self.translatable_attributes
    %i(display_name steps)
  end

  def steps
    super.map(&:with_indifferent_access)
  end
end
