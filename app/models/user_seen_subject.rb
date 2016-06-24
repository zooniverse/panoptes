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

    CodeExperiment.run "activity_by_workflow" do |e|
      e.use do
        scope = self.where(user_id: user_id)
        unless workflow_ids.empty?
          scope = scope.where(workflow_id: workflow_ids)
        end

        scope.group(:workflow_id).sum("cardinality(subject_ids)").as_json
      end

      e.try do
        scope = Classification.joins_classification_subjects
        scope = scope.where(user_id: user_id)
        scope = scope.where(workflow_id: workflow_ids) if workflow_ids.present?
        scope = scope.select("workflow_id, subject_id").group(:workflow_id).count("DISTINCT subject_id")
        scope.stringify_keys
      end
    end
  end

  def self.seen_for_user_by_workflow(user, workflow)
    Classification \
      .joins_classification_subjects
      .where(user_id: user.id, workflow_id: workflow.id)
      .select("classification_subjects.subject_id")
      .pluck(:subject_id)
  end

  def subjects_seen?(ids)
    Array.wrap(ids).any? { |id| subject_ids.include?(id) }
  end
end
