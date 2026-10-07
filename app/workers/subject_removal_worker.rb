require 'subjects/remover'

class SubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(subject_id, subject_set_id=nil, hard_delete=false)
    return unless hard_delete || Flipper.enabled?(:remove_orphan_subjects)

    remover = Subjects::Remover.new(subject_id, nil, subject_set_id)
    remover.cleanup(hard_delete: hard_delete)
  end
end
