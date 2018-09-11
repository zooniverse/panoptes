# Preview this email at
# http://localhost:3000/rails/mailers/dormant_user_mailer/dormant_user
class DormantUserMailerPreview < ActionMailer::Preview

  def dormant_user
    user = User.first
    DormantUserMailer.email_dormant_user(user)
  end
end
