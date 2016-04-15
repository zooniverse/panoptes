module CodeExperiments
  class LogReporter
    attr_reader :logger

    def initialize
      @logger = Rails.logger
    end

    def publish(experiment, result)
      # Store the timing for the control value,
      logger.debug "science.#{experiment.name}.control => #{result.control.duration}"
      # for the candidate (only the first, see "Breaking the rules" below,
      logger.debug "science.#{experiment.name}.candidate => #{result.candidates.first.duration}"

      # and counts for match/ignore/mismatch:
      if result.matched?
        logger.debug "science.#{experiment.name}.matched => #{1}"
      elsif result.ignored?
        logger.debug "science.#{experiment.name}.ignored => #{1}"
      else
        logger.debug "science.#{experiment.name}.mismatched => #{1}"
      end
    rescue StandardError => e
      Honeybadger.notify(e)
    end
  end
end
