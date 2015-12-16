module Warehouse
  class SurveyTaskFormatter < BasicTaskFormatter
    def choice(annotation)
      annotation.fetch("value").fetch("choice")
    end

    def answers(annotation)
      annotation.fetch("value").fetch("answers").to_json
    end

    def filters(annotation)
      annotation.fetch("value").fetch("filters").to_json
    end
  end
end
