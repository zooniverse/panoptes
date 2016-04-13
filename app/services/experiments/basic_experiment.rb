require 'scientist'

module Experiments
  class BasicExperiment
    include ActiveModel::Model
    include Scientist::Experiment

    attr_accessor :name

    def enabled?
      (Rails.env.staging? || Rails.env.production?) && Librato::Metrics.client.email.present?
    end

    def publish(result)
      # Store the timing for the control value,
      librato.add "science.#{name}.control" => {type: :gauge, value: result.control.duration}
      # for the candidate (only the first, see "Breaking the rules" below,
      librato.add "science.#{name}.candidate" => {type: :gauge, value: result.candidates.first.duration}

      # and counts for match/ignore/mismatch:
      if result.matched?
        librato.add "science.#{name}.matched" => {type: :counter, value: 1}
      elsif result.ignored?
        librato.add "science.#{name}.ignored" => {type: :counter, value: 1}
      else
        librato.add "science.#{name}.mismatched" => {type: :counter, value: 1}
      end

      librato.submit
    end

    def librato
      @librato ||= Librato::Metrics::Queue.new(source: Rails.env)
    end
  end
end
