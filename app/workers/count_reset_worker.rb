class CountResetWorker
  include Sidekiq::Worker

  def perform(subject_set_id)
    SubjectSet.reset_counters(subject_set_id, :set_member_subjects)
    Workflow.joins(:subject_sets).where(subject_sets: {id: subject_set_id}).find_each do |w|
      w.retired_set_member_subjects_count = SetMemberSubject.where('? = ANY(retired_workflow_ids)', w.id).count
      w.save!
    end
  end
end
