module Panoptes
  def self.user_limits
    @user_limits ||= { subjects: ENV['USER_SUBJECT_LIMIT'] || 100}
  end

  def self.max_subjects
    user_limits[:subjects]
  end
end

Panoptes.user_limits
