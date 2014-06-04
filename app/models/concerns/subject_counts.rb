module SubjectCounts
  include ActiveSupport::Concern

  def subject_count
    subject_sets.map{|set| set.set_member_subjects_count}.reduce(&:+)
  end
end
