module RetirementSchemes
  class ClassificationCount
    def initialize(count)
      @count = count
    end

    def retire?(count)
      count.classifications_count >= @count
    end
  end
end
