
module Warehouse
  module AnnotationFormatter
    def self.format(annotation, task_definition: {}, translations: {})
      formatter_class(task_definition).new(task_definition: task_definition, translations: translations).format(annotation)

    rescue StandardError
      {value: "ERROR PROCESSING ANNOTATION"}
    end

    def formatter_class(task_definition)
      case task_definition["type"]
      when "single"
        SingleTaskFormatter
      when "multiple"
        MultipleTaskFormatter
      when "drawing"
        DrawingTaskFormatter
      when "survey"
        SurveyTaskFormatter
      when "text"
        TextTaskFormatter
      # when "crop"
      #   CropTaskFormatter
      else
        BasicTaskFormatter
      end
    end
  end
end
