require 'subjects/remover'

class SubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(subject_id, subject_set_id=nil)
    return unless Flipper.enabled?(:remove_orphan_subjects)

    if subject_set_id
      # don't cleanup if linked to other SetMemberSubject
      member_set = SetMemberSubject.where(subject_id: subject_id).where.not(subject_set_id: subject_set_id)
      return unless member_set.count < 1
    end
    Subjects::Remover.new(subject_id).cleanup
  end
end
