module RetirementSchemes
  class ClassificationCount
    attr_reader :count

    def initialize(options = {})
      options = options.with_indifferent_access

      @count = options.fetch(:count)
    end

    def retire?(sw_count)
      sw_count.classifications_count >= @count
    end
  end
end
