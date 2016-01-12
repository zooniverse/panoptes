class SubjectSetSubjectCounterWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high,
    congestion: Panoptes::CongestionControlConfig.
      counter_worker.congestion_opts.merge({
        key: ->(subject_set_id) {
          "subject_set_#{ subject_set_id }_congestion_control"
        }
      })

  def perform(subject_set_id)
    set = SubjectSet.find(subject_set_id)

    set.update_attribute(:set_member_subjects_count, set.set_member_subjects.count)
  end
end
