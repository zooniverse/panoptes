
module Warehouse
  module AnnotationFormatter
    def self.format(annotation, task_definition: {}, translations: {})
      formatter_class(task_definition).format(annotation, task_definition: task_definition, translations: translations)
    rescue StandardError
      raise if Rails.env.development?
      {value: "ERROR PROCESSING ANNOTATION"}
    end

    def self.formatter_class(task_definition)
      case task_definition["type"]
      when "single" then SingleTaskFormatter
      when "multiple" then MultipleTaskFormatter
      when "drawing" then DrawingTaskFormatter
      when "survey" then SurveyTaskFormatter
      when "text" then TextTaskFormatter
      when "crop" then CropTaskFormatter
      else BasicTaskFormatter
      end
    end
  end
end
