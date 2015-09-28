class AggregationDataMailer < ApplicationMailer

  def aggregation_data(project, data_url, emails)
    @project = project
    @url = data_url
    mail(to: emails, subject: "Aggregation Data is Ready")
  end

end
