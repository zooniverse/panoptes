require 'subjects/remover'

class SubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_low

  def perform(subject_id)
    #TODO: figure out why these subject deletes are maxing out the DB CPU
    # in the meantime just move on and leave them as inactive
    # Subjects::Remover.new(subject_id).cleanup
  end
end
