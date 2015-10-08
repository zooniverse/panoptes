class Tutorial < ActiveRecord::Base
  include Linkable
  include RoleControl::ParentalControlled

  belongs_to :workflow
  has_many :attached_images, -> { where(type: "tutorial_attached_image") }, class_name: "Medium",
    as: :linked
  has_one :project, foreign_key: :default_tutorial_id

  validates_presence_of :workflow
  validates_uniqueness_of :language, case_sensitive: false, scope: :workflow_id
  validates :language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}

  can_through_parent :workflow, :update, :index, :show, :destroy

  validate do |tut|
    tut.steps.each.with_index do |step, i|
      unless step.has_key?(:content)
        tut.errors.add(:"steps.#{i}.content", "Tutorial step must have content")
      end

      unless step.has_key?(:title)
        tut.errors.add(:"steps.#{i}.title", "Tutorial step must have title")
      end
    end
  end

  def steps
    super.map(&:with_indifferent_access)
  end
end
