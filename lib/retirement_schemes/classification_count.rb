module RetirementSchemes
  class ClassificationCount
    def initialize(count)
      @count = count
    end

    def retire?(sms)
      sms.classification_count >= @count
    end
  end
end
