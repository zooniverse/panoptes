class Tutorial < ActiveRecord::Base
  include Linkable
  include RoleControl::ParentalControlled

  belongs_to :project
  has_many :workflow_tutorials
  has_many :workflows, through: :workflow_tutorials
  has_many :attached_images, -> { where(type: "tutorial_attached_image") }, class_name: "Medium",
    as: :linked

  validates_presence_of :project

  can_through_parent :project, :update, :index, :show, :destroy

  def steps
    super.map(&:with_indifferent_access)
  end
end
