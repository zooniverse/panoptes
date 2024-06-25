# frozen_string_literal: true

class AggregationCompletedMailerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(agg_id)
    aggregation = Aggregation.find(agg_id)
    AggregationCompletedMailer.aggregation_complete(aggregation).deliver
  end
end
