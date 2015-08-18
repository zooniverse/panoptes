class UserProjectPreference < ActiveRecord::Base
  include Preferences

  preferences_for :project, :classifiers_count

  def summated_activity_count
    if legacy_count.blank?
      activity_count
    else
      valid_legacy_count_values.reduce(:+)
    end
  end

  private

  def valid_legacy_count_values
    legacy_count.values.compact
  end
end
