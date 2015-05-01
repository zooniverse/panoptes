class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@zooniverse.org"
  layout 'mailer'
end
