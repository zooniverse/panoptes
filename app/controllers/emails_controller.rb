class EmailsController < ActionController::Base

  UNSUBSCRIBE_USER_ATTRIBUTES = {
    global_email_communication: false,
    project_email_communication: false,
    beta_email_communication: false,
    nasa_email_communication: false
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
      if user = User.user_from_unsubscribe_token(token)
        revoke_email_subscriptions(user)
      end
      redirect_to "#{Panoptes.unsubscribe_redirect}?processed=true"
    else
      redirect_to "#{Panoptes.unsubscribe_redirect}"
    end
  end

  def unsubscribe_email
    if email = params.delete(:email)
      if user = User.find_for_authentication(email: email)
        revoke_email_subscriptions(user)
      end
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def revoke_email_subscriptions(user)
    user.update!(UNSUBSCRIBE_USER_ATTRIBUTES)
    UserProjectPreference
      .where(user_id: user.id)
      .update_all(email_communication: false)
  rescue ActiveRecord::RecordInvalid
    nil
  end
end
