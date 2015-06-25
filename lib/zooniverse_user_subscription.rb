class ZooniverseUserSubscription < ActiveRecord::Base

  class MissingLegacyProject < StandardError; end

  ZOO_USER_BATCH_SIZE = 1000

  establish_connection :"zooniverse_home_#{ Rails.env }"
  self.table_name = 'subscriptions'

  belongs_to :zooniverse_user, foreign_key: "user_id"
  serialize :summary, Hash

  def self.import_zoo_user_subscriptions(user_logins=nil)
    setup_caches
    zoo_user_scope = zoo_users_to_import(user_logins)
    total_batches = zoo_user_scope.count / ZOO_USER_BATCH_SIZE
    zoo_user_scope.find_in_batches.with_index do |zoo_users, batch|
      puts "Processing zoo user batch: #{ batch + 1} out of #{total_batches}"
      import_batch(zoo_users)
    end
  end

  def self.setup_caches
    @cached_projects = {}
    @cached_users = {}
  end

  def self.zoo_users_to_import(user_logins)
    if user_logins.blank?
      ZooniverseUser.all
    else
      ZooniverseUser.where(users: { login: user_logins })
    end.select(:id)
  end

  def self.import_batch(zoo_users)
    #reset the cache for each batch
    @cached_users = {}
    import_user_scope = zoo_project_subscriptions(zoo_users.map(&:id))
    total = import_user_scope.count.keys.count
    import_user_scope.find_each.with_index do |user_project_sub, index|
      puts "#{ index } / #{ total }" if index % 1_000 == 0
      unless user_project_sub.empty_summary?
        user_project_sub.import
      end
    end
  end

  def self.cached_users
    @cached_users
  end

  def self.cached_projects
    @cached_projects
  end

  def self.zoo_project_subscriptions(user_ids)
    self.where.not(user_id: nil, project_id: nil)
      includes(:zooniverse_user)
      .joins(:zooniverse_user)
      .where(users: { id: user_ids })
      .distinct
      .group(:user_id, :project_id)
  end

  def import
    return if user_id.nil? || empty_summary?
    zoo_project = find_legacy_migrated_project
    if panoptes_user = find_migrated_user
      migrated_upp = UserProjectPreference.find_or_initialize_by(project_id: zoo_project.id,
                                                                 user_id: panoptes_user.id)
      migrated_upp.activity_count = summate_activity_counts
      migrated_upp.email_communication = (notifications || true)
      migrated_upp.save! if migrated_upp.changed?
    end
  end

  def empty_summary?
    summary.empty?
  end

  private

  def find_legacy_migrated_project
    return self.class.cached_projects[project_id] if self.class.cached_projects.has_key?(project_id)
    legacy_project = Project.where(migrated: true)
      .where("configuration ->> 'zoo_home_project_id' = '#{project_id}'")
      .first
    unless legacy_project
      raise MissingLegacyProject.new("Legacy project missing make sure it has been migrated!")
    end
    self.class.cached_projects[project_id] = legacy_project
  end

  def find_migrated_user
    if self.class.cached_users.has_key?(zooniverse_user.id)
      self.class.cached_users[zooniverse_user.id]
    else
      migrated_user = User.where(zooniverse_id: zooniverse_user.id)
        .or(User.where(email: zooniverse_user.email))
        .first
      unless migrated_user
        p "Skipping subscription for non-migrated user account: #{zooniverse_user.login}"
      end
      self.class.cached_users[zooniverse_user.id] = migrated_user
    end
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
