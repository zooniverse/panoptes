class ZooniverseUserSubscription < ActiveRecord::Base
  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'subscriptions'

  belongs_to :zooniverse_user, foreign_key: "user_id"
  serialize :summary, Hash

  def self.import_user_subscriptions(user_logins=nil)
    zoo_subscriptions_scope(user_logins).find_each do |zoo_sub_scope|
      zoo_sub_scope.import
    end
  end

  def import
    return unless legacy_migrated_project
    if panoptes_user = User.find_by(display_name: zooniverse_user.login)
      binding.pry
      migrated_upp = UserProjectPreference.find_or_initialize_by(project_id: zoo_project_id, user_id: panoptes_user.id)
      migrated_upp.activity_count = self.summary
      migrated_upp.email_communication = (self.notifications || true)
      begin
        migrated_upp.save!
      rescue
        binding.pry
      end
    end
  end

  private

  def self.zoo_subscriptions_scope(user_logins)
    if user_logins.blank?
      self.includes(:zooniverse_user).joins(:zooniverse_user)
    else
      self.includes(:zooniverse_user)
        .joins(:zooniverse_user)
        .where(users: { login: user_logins })
    end
  end

  def legacy_migrated_project
    zoo_project_id = self.project_id
    Project.where(legacy)
  end
end
