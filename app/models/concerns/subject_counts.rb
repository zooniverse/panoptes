module SubjectCounts
  include ActiveSupport::Concern

  def subject_count
    subject_sets.sum :set_member_subjects_count
  end
end
