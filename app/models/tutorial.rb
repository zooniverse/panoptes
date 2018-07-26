class Tutorial < ActiveRecord::Base

  belongs_to :project
  has_many :workflow_tutorials
  has_many :workflows, through: :workflow_tutorials
  has_many :attached_images, -> { where(type: "tutorial_attached_image") }, class_name: "Medium",
    as: :linked

  validates_presence_of :project

  def steps
    super.map(&:with_indifferent_access)
  end
end
