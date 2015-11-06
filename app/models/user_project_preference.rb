class UserProjectPreference < ActiveRecord::Base
  include Preferences

  preferences_for :project

  after_create do
    Project.update_counters project.id, classifiers_count: 1
  end

  after_destroy do
    if project.launch_date.nil? || project.classifications.where("user_id = ? AND created_at >= ?", user_id, project.launch_date)
      Project.update_counters project.id, classifiers_count: -1
    end
  end

  def summated_activity_count
    if legacy_count.blank?
      activity_count
    else
      valid_legacy_count_values.reduce(:+)
    end
  end

  private

  def valid_legacy_count_values
    legacy_count.values.compact.map(&:to_i)
  end
end
