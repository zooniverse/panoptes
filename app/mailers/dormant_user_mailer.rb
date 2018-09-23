class DormantUserMailer < ApplicationMailer
  layout false
  DEFAULT_SUBJECT = "We still need your help on the Zooniverse".freeze

  def email_dormant_user(user)
    @user = user
    @email_to = user.email
    @last_project = last_classified_project(user.id)
    google_analytic_prefix = "?utm_source=Newsletter&utm_campaign="
    @dormant_with_classification_ga_code = "#{google_analytic_prefix}dormant_with_classifications"
    @dormant_with_last_project_complete_ga_code = "#{google_analytic_prefix}dormant_with_last_project_complete"
    @dormant_without_classification_ga_code = "#{google_analytic_prefix}dormant_no_classifications"
    mail(to: @email_to, subject: DEFAULT_SUBJECT)
  end

  def last_classified_project(user_id)
    upp = UserProjectPreference
      .where(user_id: user_id)
      .where.not(email_communication: nil)
      .order(updated_at: :desc)
      .first
    upp ? upp.project : nil
  end
end
