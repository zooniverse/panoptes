require "spec_helper"

RSpec.describe ClassificationDataMailer, :type => :mailer do
  it_behaves_like "data mailer", "Classification", :classification_data
end
