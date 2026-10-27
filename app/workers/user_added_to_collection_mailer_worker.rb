# frozen_string_literal: true

class UserAddedToCollectionMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  attr_reader :user, :collection

  def perform(user_id, collection_id, roles)
    @user = User.find(user_id)
    if @user&.receives_email? && roles
      collection = Collection.find(collection_id)
      UserAddedToCollectionMailer.added_to_collection(user, collection, roles).deliver
    end
  rescue ActiveRecord::RecordNotFound
    nil
  rescue Net::SMTPSyntaxError, Net::SMTPFatalError
    @user.update_attribute(:valid_email, false)
  end
end
