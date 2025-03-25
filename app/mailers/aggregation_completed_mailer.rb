# frozen_string_literal: true

class AggregationCompletedMailer < ApplicationMailer
  layout false

  def aggregation_complete(agg)
    @user = User.find(agg.user_id)
    @email_to = @user.email
    base_url = ENV.fetch('AGGREGATION_STORAGE_BASE_URL', '')
    @zip_url = "#{base_url}/#{agg.uuid}/#{agg.uuid}.zip"
    @reductions_url = "#{base_url}/#{agg.uuid}/reductions.csv"

    @success = agg.completed?
    agg_status = @success ? 'was successful!' : 'failed'
    subject = "Your workflow aggregation #{agg_status}"

    mail(to: @email_to, subject: subject)
  end
end
