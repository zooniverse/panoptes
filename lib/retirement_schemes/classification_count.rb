module RetirementSchemes
  class ClassificationCount
    def initialize(count)
      @count = count
    end

    def retire?(sw_count)
      if disabled?
        false
      else
        sw_count.classifications_count >= @count
      end
    end

    def disabled?
      !!@count.to_s.match(/\Adisabled\z/i)
    end
  end
end
