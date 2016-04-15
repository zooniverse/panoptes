module CodeExperiments
  class LibratoReporter
    def initialize
      @librato = Librato::Metrics::Queue.new(source: Rails.env)
    end

    def publish(experiment, result)
      return false unless Librato::Metrics.client.email.present?

      # Store the timing for the control value,
      librato.add "science.#{experiment.name}.control" => {type: :gauge, value: result.control.duration}
      # for the candidate (only the first, see "Breaking the rules" below,
      librato.add "science.#{experiment.name}.candidate" => {type: :gauge, value: result.candidates.first.duration}

      # and counts for match/ignore/mismatch:
      if result.matched?
        librato.add "science.#{experiment.name}.matched" => {type: :counter, value: 1}
      elsif result.ignored?
        librato.add "science.#{experiment.name}.ignored" => {type: :counter, value: 1}
      else
        librato.add "science.#{experiment.name}.mismatched" => {type: :counter, value: 1}
      end

      librato.submit
    end
  end
end
