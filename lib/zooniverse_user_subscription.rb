class ZooniverseUserSubscription < ActiveRecord::Base

  class MissingLegacyProject < StandardError; end

  ZOO_USER_BATCH_SIZE = 1000

  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'subscriptions'

  belongs_to :zooniverse_user, foreign_key: "user_id"
  serialize :summary, Hash

  def self.import_zoo_user_subscriptions(user_logins=nil)
    import_ids = zoo_users_to_import(user_logins)
    subs = zoo_project_subscriptions(import_ids)
    subs.find_each.with_index(&:import)
  end

  def self.zoo_users_to_import(user_logins)
    if user_logins.blank?
      nil
    else
      ZooniverseUser.where(users: { login: user_logins }).pluck(:id)
    end
  end

  def self.zoo_project_subscriptions(user_ids)
    query = self.where.not(user_id: nil, project_id: nil)
    query = query.where(user_id: user_ids) if user_ids
    query
  end

  def import(index)
    return if user_id.nil? || empty_summary?
    zoo_project = find_legacy_migrated_project
    if panoptes_user = find_migrated_user
      migrated_upp = UserProjectPreference.find_or_initialize_by(project_id: zoo_project.id,
                                                                 user_id: panoptes_user.id)
      migrated_upp.legacy_count = summate_activity_counts
      migrated_upp.email_communication = (notifications || true)
      migrated_upp.save! if migrated_upp.changed?
    end
  end

  def empty_summary?
    summary.empty?
  end

  private

  def find_legacy_migrated_project
    legacy_project = Project.where(migrated: true)
      .where("configuration ->> 'zoo_home_project_id' = '#{project_id}'")
      .first
    unless legacy_project
      raise MissingLegacyProject.new("Legacy project missing make sure it has been migrated!")
    end
    legacy_project
  end

  def find_migrated_user
    unless migrated_user = User.find_by(zooniverse_id: user_id)
      p "Skipping subscription for non-migrated user account: #{zooniverse_user.login}"
    end
    migrated_user
  end

  # Summate all the activity counts for the user : project id combo
  # original DB has no validations and there are duplicates with different values
  def summate_activity_counts
    all_user_projects_subscriptions.reduce({}) do |counts, subscription|
      next if subscription.empty_summary?
      summary = subscription.summary
      summary.each do |workflow, value|
        counts[workflow] ||= 0
        counts[workflow] += value[:count].to_i
      end
      counts
    end
  end

  def all_user_projects_subscriptions
    self.class.where(user_id: self.user_id, project_id: self.project_id).select(:id, :summary)
  end
end
