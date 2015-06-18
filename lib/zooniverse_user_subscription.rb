class ZooniverseUserSubscription < ActiveRecord::Base

  class MissingLegacyProject < StandardError; end

  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'subscriptions'

  belongs_to :zooniverse_user, foreign_key: "user_id"
  serialize :summary, Hash

  def self.import_zoo_user_subscriptions(user_logins=nil)
    zoo_project_subscriptions(user_logins).find_each do |user_project_sub|
      unless user_project_sub.empty_summary?
        user_project_sub.import
      end
    end
  end

  def self.zoo_project_subscriptions(user_logins)
    subs_scope = self.where.not(user_id: nil, project_id: nil)
      .includes(:zooniverse_user)
      .joins(:zooniverse_user)
      .distinct
    unless user_logins.blank?
      subs_scope = subs_scope.merge(ZooniverseUser.where(users: { login: user_logins }))
    end
    subs_scope.group(:user_id, :project_id)
  end

  def import
    return if user_id.nil? || empty_summary?
    zoo_project = find_legacy_migrated_project
    if panoptes_user = find_migrated_user
      migrated_upp = UserProjectPreference.find_or_initialize_by(project_id: zoo_project.id,
                                                                 user_id: panoptes_user.id)
      migrated_upp.activity_count = summate_activity_counts
      migrated_upp.email_communication = (notifications || true)
      migrated_upp.save!
    end
  end

  def empty_summary?
    summary.empty?
  end

  private

  def find_legacy_migrated_project
    zoo_project_id = project_id
    legacy_project = Project.where(migrated: true)
      .where("configuration ->> 'zoo_home_project_id' = '#{zoo_project_id}'")
      .first
    unless legacy_project
      raise MissingLegacyProject.new("Legacy project missing make sure it has been migrated!")
    end
    legacy_project
  end

  def find_migrated_user
    unless migrated_user = User.find_by(login: zooniverse_user.login)
      p "Skipping subscription for non-migrated user account: #{zooniverse_user.login}"
    end
    migrated_user
  end

  # Summate all the activity counts for the user : project id combo
  # original DB has no validations and there are duplicates with different values
  def summate_activity_counts
    activity_count = 0
    all_user_projects_subscriptions.find_each do |subscription|
      next if subscription.empty_summary?
      if count = subscription.summary.values.first[:count].to_i
        activity_count += count
      end
    end
    activity_count
  end

  def all_user_projects_subscriptions
    self.class.where(user_id: self.user_id, project_id: self.project_id).select(:id, :summary)
  end
end
