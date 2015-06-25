class EmailsController < ActionController::Base

  UNSUBSCRIBE_USER_ATTRIBUTES = {
    global_email_communication: false,
    project_email_communication: false,
    beta_email_communication: false
  }

  def unsubscribe
    respond_to do |format|
      format.html { unsubscribe_via_token }
      format.json { unsubscribe_via_email }
    end
  end

  private

  def unsubscribe_via_token
    token = params.delete(:token)
    user = if token
       User.user_from_unsubscribe_token(token)
    end
    unsubscribe_user(user)
  end

  def unsubscribe_via_email
    email = params.delete(:email)
    user = if email
      User.find_by(email: email)
    end
    unsubscribe_user(user)
  end

  def unsubscribe_user(user)
    if user
      suffix = revoke_email_subscriptions(user) ? nil : "?failed=true"
      redirect_to "#{Panoptes.unsubscribe_redirect}#{suffix}"
    else
      head :unprocessable_entity
    end
  end

  def revoke_email_subscriptions(user)
    user.update!(UNSUBSCRIBE_USER_ATTRIBUTES)
    UserProjectPreference.where(user_id: user.id).update_all(email_communication: false)
    UnsubscribeWorker.perform_async(user.email)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
