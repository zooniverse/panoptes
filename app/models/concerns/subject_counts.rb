module SubjectCounts
  include ActiveSupport::Concern

  def subjects_count
    @subject_count ||= subject_sets.sum :set_member_subjects_count
  end

  def retired_subjects_count
    @retired_subject_count ||= subject_sets.sum :retired_set_member_subjects_count
  end
  
  def finished?
    subjects_count == retired_subjects_count
  end
end
