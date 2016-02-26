module SubjectCounts
  include ActiveSupport::Concern

  def subjects_count
    @subject_count ||= subject_sets.sum :set_member_subjects_count
  end

  def retired_subjects_count
    @retired_subject_count ||= workflows.sum :retired_set_member_subjects_count
  end

  def finished?
    @finished ||= if subject_sets.empty? || subjects_count == 0
      false
    else
      retired_subjects_count >= subjects_count
    end
  end
end
