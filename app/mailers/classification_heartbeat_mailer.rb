class ClassificationHeartbeatMailer < ApplicationMailer

  def missing_classifications(emails, window_period)
    @window_period = window_period
    mail(to: emails, subject: "No classification data received")
  end
end
