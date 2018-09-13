class EmailDormantUsersWorker
  include Sidekiq::Worker

  class DoNotRunOnStagingError < StandardError; end

  def perform(num_days_since_activity, ending_in)
    raise DoNotRunOnStagingError if Rails.env.staging?

    user_ids_ending_in_scope = User.subset_selection(ending_in)
    User.dormant(num_days_since_activity, user_ids_ending_in_scope) do |dormant_user|
      DormantUserMailerWorker.perform_async(dormant_user.id)
    end
  end
end
