require 'subjects/remover'

class SubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform(subject_id)
    Subjects::Remover.new(subject_id).cleanup
  rescue Subjects::Remover::NonOrphan
  end
end
