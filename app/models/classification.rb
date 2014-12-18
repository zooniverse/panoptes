class Classification < ActiveRecord::Base
  belongs_to :set_member_subject, counter_cache: true
  belongs_to :project, counter_cache: true
  belongs_to :user, counter_cache: true
  belongs_to :workflow, counter_cache: true
  belongs_to :user_group, counter_cache: true

  enum expert_classifier: [:expert, :owner]

  validates_presence_of :set_member_subject, :project, :workflow,
                        :annotations, :user_ip

  validates :user, presence: true, if: :incomplete?
  validate :metadata, :required_metadata_present
  validate :validate_gold_standard

  def self.visible_to(actor, as_admin: false)
    ClassificationVisibilityQuery.new(actor, self).build(as_admin)
  end

  def self.can_create?(actor)
    true
  end

  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
  end

  def in_show_scope?(actor)
    self.class.visible_to(actor).exists?(self)
  end

  def creator?(actor)
    user == actor.user
  end

  def complete?
    completed
  end

  def incomplete?
    !completed
  end

  def anonymous?
    !user
  end

  def metadata
    read_attribute(:metadata).with_indifferent_access
  end

  private

  def required_metadata_present
    %i(started_at finished_at workflow_version user_language user_agent).each do |key|
      unless metadata.has_key? key
        errors.add(:metadata, "must have #{key} metadata")
      end
    end
  end

  def validate_gold_standard
    ClassificationValidator.new(self).validate_gold_standard
  end
end
