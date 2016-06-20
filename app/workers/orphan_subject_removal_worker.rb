class OrphanSubjectRemovalWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_medium

  def perform
    orphans.map(&:destroy)
  end

  private

  def orphans
    Subject
    .joins("LEFT OUTER JOIN set_member_subjects ON set_member_subjects.subject_id = subjects.id")
    .where("subjects.id IS NOT NULL AND set_member_subjects.id IS NULL")
    .joins("LEFT OUTER JOIN classification_subjects ON classification_subjects.subject_id = subjects.id")
    .where("subjects.id IS NOT NULL AND classification_subjects.subject_id IS NULL")
  end
end
