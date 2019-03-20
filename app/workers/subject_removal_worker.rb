class SubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(subject_id)
    if Panoptes.flipper["remove_orphan_subjects"].enabled?
      Subjects::Remover.new(subject_id).cleanup
    end
  end
end
