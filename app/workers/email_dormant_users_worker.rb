class EmailDormantUsersWorker
  include Sidekiq::Worker

  class DoNotRunOnStagingError < StandardError; end

  def perform(num_days_since_activity, ending_in)
    raise DoNotRunOnStagingError if Rails.env.staging?

    selected_users = User.subset_selection(ending_in)
    User.dormant(num_days_since_activity, selected_users) do |dormant_user|
      DormantUserMailerWorker.perform_async(dormant_user.id)
    end
  end
end
