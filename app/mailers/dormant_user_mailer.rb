class DormantUserMailer < ApplicationMailer

  DEFAULT_SUBJECT = "We still need your help on the Zooniverse".freeze

  def email_dormant_user(user)
    @user = user
    @email_to = user.email
    @last_project = last_classified_project(user.id)
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end

  # this is a target to move into the user model? or maybe the UPP model?
  # instead of re-writing this here and in user.rb
  def last_classified_project(user_id)
    upp = UserProjectPreference
      .where(user_id: user_id)
      .where.not(email_communication: nil)
      .order(updated_at: :desc)
      .first
    upp ? upp.project : nil
  end
end
