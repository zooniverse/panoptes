class Classification < ActiveRecord::Base
  belongs_to :project, counter_cache: true
  belongs_to :user, counter_cache: true
  belongs_to :workflow, counter_cache: true
  belongs_to :user_group, counter_cache: true

  enum expert_classifier: [:expert, :owner]

  validates_presence_of :subject_ids, :project,
                        :workflow, :annotations, :user_ip

  validates :user, presence: true, if: :incomplete?
  validate :metadata, :required_metadata_present
  validate :validate_gold_standard

  scope :incomplete, -> { where(completed: false) }
  scope :created_by, -> (user) { where(user: user) }
  scope :complete, -> { where(completed: true) }

  def self.scope_for(action, user, opts={})
    return all if user.is_admin?
    case action
    when :show, :index
      query = joins(:project).merge(Project.scope_for(:update, user))
              .merge(complete)
              .union_all(incomplete_for_user(user))
      # Workaround Broken Bind Value Assignment in Subqueries in Rails 4.1
      # This is fixed in Rails 4.2 when we're able to to migrate to that
      # Unfortunately this isn't needed in JRuby so I have to test for platform on this class
#      query.bind_values = [query.bind_values.first] unless RUBY_PLATFORM == 'java'
      query
    when :update, :destroy
      incomplete_for_user(user)
    else
      none
    end
  end

  def self.incomplete_for_user(user)
    incomplete.merge(created_by(user.user))
  end

  def created_and_incomplete?(actor)
    creator?(actor) && incomplete?
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
