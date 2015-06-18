# Preview all emails at http://localhost:3000/rails/mailers/subject_data_mailer
class SubjectDataMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/subject_data_mailer/subject_data
  def subject_data
    SubjectDataMailer.subject_data
  end

end
