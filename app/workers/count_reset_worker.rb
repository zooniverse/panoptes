class CountResetWorker
  include Sidekiq::Worker

  def perform(subject_set_id)
    reset_set_member_subject_counter(subject_set_id)
    reset_retired_subject_counter(subject_set_id)
  end

  private

  def reset_set_member_subject_counter(subject_set_id)
    SubjectSet.reset_counters(subject_set_id, :set_member_subjects)
  end

  def reset_retired_subject_counter(subject_set_id)
    Workflow.joins(:subject_sets).where(subject_sets: {id: subject_set_id}).find_each do |w|
      retired_subjects = SubjectWorkflowCount.by_set(subject_set_id).where(workflow_id: w.id)
      w.retired_set_member_subjects_count = retired_subjects.count
      w.save!
    end
  rescue ActiveRecord::RecordNotFound
  end
end
