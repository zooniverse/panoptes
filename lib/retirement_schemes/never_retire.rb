module RetirementSchemes
  class NeverRetire
    def initialize(options = {})
    end

    def retire?(sw_count)
      false
    end
  end
end
