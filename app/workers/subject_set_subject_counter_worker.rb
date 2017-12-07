class SubjectSetSubjectCounterWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high,
    congestion: Panoptes::CongestionControlConfig.
      counter_worker.congestion_opts.merge({
        reject_with: :reschedule,
        key: ->(subject_set_id) {
          "subject_set_#{ subject_set_id }_counter_worker"
        }
      }),
    unique: :until_executing

  def self.perform_async(subject_set_id)
    if SubjectSet === subject_set_id
      Honeybadger.notify("WTF is happening with SubjectSetSubjectCounterWorker: expected integer, got SubjectSet: #{subject_set_id.inspect}")
    end

    super
  end

  def perform(subject_set_id)
    set = SubjectSet.find(subject_set_id)
    set.update_column(:set_member_subjects_count, set.set_member_subjects.count)
    set.touch
  end
end
