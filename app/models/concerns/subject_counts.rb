module SubjectCounts
  include ActiveSupport::Concern

  def subjects_count
    subject_sets.sum :set_member_subjects_count
  end
end
