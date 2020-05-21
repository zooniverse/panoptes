class SubjectSetSubjectCounterWorker
  include Sidekiq::Worker

  sidekiq_options(
    queue: :data_high,
    congestion:
      {
        interval: ENV.fetch('COUNTER_CONGESTION_OPTS_INTERVAL', 360).to_i,
        max_in_interval: ENV.fetch('COUNTER_CONGESTION_OPTS_MAX_IN_INTERVAL', 10).to_i,
        min_delay: ENV.fetch('COUNTER_CONGESTION_OPTS_MIN_DELAY', 180).to_i,
        reject_with: :reschedule,
        key: ->(subject_set_id) { "subject_set_#{subject_set_id}_counter_worker" }
      },
    lock: :until_executing
  )

  def perform(subject_set_id)
    # recount this set's subjects
    set = SubjectSet.find(subject_set_id)
    set.update_column(:set_member_subjects_count, set.set_member_subjects.count)
    set.touch

    # recount the subjects for each workflow this set is in
    set.workflow_ids.each do |workflow_id|
      WorkflowSubjectsCountWorker.perform_async(workflow_id)
    end
  end
end
