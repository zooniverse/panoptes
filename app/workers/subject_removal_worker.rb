require 'subjects/remover'

class SubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(subject_id, subject_set_id=nil)
    return unless Flipper.enabled?(:remove_orphan_subjects)

    Subjects::Remover.new(subject_id, nil, subject_set_id).cleanup
  end
end
