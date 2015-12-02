module RetirementSchemes
  class NeverRetire
    def initialize
    end

    def retire?(sw_count)
      false
    end
  end
end
