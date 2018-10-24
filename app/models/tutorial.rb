class Tutorial < ActiveRecord::Base
  include Translatable

  belongs_to :project
  has_many :workflow_tutorials
  has_many :workflows, through: :workflow_tutorials
  has_many :attached_images, -> { where(type: "tutorial_attached_image") }, class_name: "Medium",
    as: :linked

  validates_presence_of :project

  def self.translatable_attributes
    %i(display_name steps)
  end

  # TODO: Add Versioning to this model, and then remove this override
  def latest_version_id
    0
  end

  def steps
    super.map(&:with_indifferent_access)
  end
end
