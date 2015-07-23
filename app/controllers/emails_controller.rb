class EmailsController < ActionController::Base

  UNSUBSCRIBE_USER_ATTRIBUTES = {
    global_email_communication: false,
    project_email_communication: false,
    beta_email_communication: false
  }

  def unsubscribe_via_token
    respond_to do |format|
      format.html { unsubscribe_token }
    end
  end

  def unsubscribe_via_email
    respond_to do |format|
      format.json { unsubscribe_email }
    end
  end


  private

  def unsubscribe_token
    if token = params.delete(:token)
      user = if token
         User.user_from_unsubscribe_token(token)
      end
      revoke_email_subscriptions(user) if user
      redirect_to "#{Panoptes.unsubscribe_redirect}?processed=true"
    else
      redirect_to "#{Panoptes.unsubscribe_redirect}"
    end
  end

  def unsubscribe_email
    if email = params.delete(:email)
      user = if email
        User.find_by(email: email)
      end
      revoke_email_subscriptions(user) if user
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def revoke_email_subscriptions(user)
    user.update!(UNSUBSCRIBE_USER_ATTRIBUTES)
    UserProjectPreference.where(user_id: user.id).update_all(email_communication: false)
    UnsubscribeWorker.perform_async(user.email)
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
