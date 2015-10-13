class Tutorial < ActiveRecord::Base
  include Linkable
  include RoleControl::ParentalControlled

  belongs_to :project
  has_many :attached_images, -> { where(type: "tutorial_attached_image") }, class_name: "Medium",
    as: :linked

  validates_presence_of :project
  validates_uniqueness_of :language, case_sensitive: false, scope: :project_id
  validates :language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}

  can_through_parent :project, :update, :index, :show, :destroy

  def steps
    super.map(&:with_indifferent_access)
  end
end
