class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  def self.add_seen_subjects_for_user(user: nil, workflow: nil, subject_ids: nil)
    newly_created = false
    uss = where(user: user, workflow: workflow).first_or_create! do |uss_to_create|
      newly_created = true
      uss_to_create.user = user
      uss_to_create.workflow = workflow
      uss_to_create.subject_ids = subject_ids
    end

    return uss if newly_created

    # existing records we need to uniquely update the subject_ids using an atomic update via update_all
    where(user: user, workflow: workflow).update_all(['subject_ids = uniq(subject_ids + array[?])', subject_ids])
    # touch the updated_at timestamp on the record to track when the subject_ids were last modified
    uss.touch
  end

  def self.count_user_activity(user_id, workflow_ids=[])
    workflow_counts = activity_by_workflow(user_id, workflow_ids)
    workflow_counts.values.sum
  end

  def self.activity_by_workflow(user_id, workflow_ids=[])
    workflow_ids = Array.wrap(workflow_ids)
    scope = self.where(user_id: user_id)
    unless workflow_ids.empty?
      scope = scope.where(workflow_id: workflow_ids)
    end
    scope.group(:workflow_id).sum("cardinality(subject_ids)").as_json
  end

  def subjects_seen?(ids)
    Array.wrap(ids).any? { |id| subject_ids.include?(id) }
  end
end
