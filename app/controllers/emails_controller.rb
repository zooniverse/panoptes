class EmailsController < ActionController::Base

  UNSUBSCRIBE_USER_ATTRIBUTES = {
    global_email_communication: false,
    project_email_communication: false,
    beta_email_communication: false
  }

  def unsubscribe
    respond_to do |format|
      format.html { unsubscribe_via_token }
    end
  end

  private

  def unsubscribe_via_token
    token = params.delete(:token)
    if token && user = User.user_from_unsubscribe_token(token)
      suffix = revoke_email_subscriptions(user) ? nil : "?failed=true"
      redirect_to "#{Panoptes.unsubscribe_redirect}#{suffix}"
    else
      head :unprocessable_entity
    end
  end

  def revoke_email_subscriptions(user)
    user.update!(UNSUBSCRIBE_USER_ATTRIBUTES)
    UserProjectPreference.where(user_id: user.id)
      .update_all(email_communication: false)
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
