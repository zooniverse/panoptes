require "spec_helper"

RSpec.describe SubjectDataMailer, type: :mailer do
  it_behaves_like "data mailer", "Subject", :subject_data
end
