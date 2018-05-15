class UserSeenSubject < ActiveRecord::Base
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  def self.add_seen_subjects_for_user(user: nil, workflow: nil, subject_ids: nil)
    uss = where(user: user, workflow: workflow)
    if uss.exists?
      uss.update_all(["subject_ids = uniq(subject_ids + array[?])", subject_ids])
    else
      uss.create!(subject_ids: subject_ids)
    end
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

  def self.has_seen_subjects_for_workflow?(user, workflow, subject_ids)
    where(user: user, workflow: workflow)
    .where("subject_ids && ARRAY[?]::integer[]", subject_ids)
    .exists?
  end

  def subjects_seen?(ids)
    Array.wrap(ids).any? { |id| subject_ids.include?(id) }
  end
end
