class ZooniverseUserSubscription < ActiveRecord::Base

  class MissingLegacyProject < StandardError; end

  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'subscriptions'

  belongs_to :zooniverse_user, foreign_key: "user_id"
  serialize :summary, Hash

  def self.import_zoo_user_subscriptions(user_logins=nil)
    zoo_subscriptions_scope(user_logins).find_each do |zoo_subscription|
      zoo_subscription.import
    end
  end

  def self.zoo_subscriptions_scope(user_logins)
    if user_logins.blank?
      self.includes(:zooniverse_user).joins(:zooniverse_user)
    else
      self.includes(:zooniverse_user)
        .joins(:zooniverse_user)
        .where(users: { login: user_logins })
    end
  end

  def import
    return if missing_required_information?
    zoo_project = find_legacy_migrated_project
    if panoptes_user = find_migrated_user
      migrated_upp = UserProjectPreference.find_or_initialize_by(project_id: zoo_project.id,
                                                                 user_id: panoptes_user.id)
      migrated_upp.activity_count = summate_activity_count(migrated_upp.activity_count)
      migrated_upp.email_communication = (notifications || true)
      migrated_upp.save!
    end
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
    unless migrated_user = User.find_by(display_name: zooniverse_user.login)
      p "Skipping subscription for non-migrated user account: #{zooniverse_user.login}"
    end
    migrated_user
  end

  def missing_required_information?
    user_id.nil? || summary.empty?
  end

  def summate_activity_count(existing_count)
    current_count = (existing_count || 0)
    new_count     = summary.values.first[:count].to_i
    current_count + new_count
  end
end
