# frozen_string_literal: true

# Copy of the AnnotationForCsv class bringing over the default annotation formatting behaviour
# an updating to handel the "classifier_version"=>"2.0" as noted on
# classification metadata FEM classifications vs PFE (v1 and missing on the metadata)
#
# Overtime this class will evolve behaviour to handle the distinct classification annotation formats
# if it doesn't these two behaviours can be refactored for collaborating classes
# to provide csv converstion of the differing annotation formats
module Formatter
  module Csv
    module V2
      class Annotation
        attr_reader :classification, :current_annotation, :cache, :default_formatter, :workflow_information, :task_info

        def initialize(classification, annotation, cache, default_formatter=nil)
          @classification = classification
          @current_annotation = annotation.dup.with_indifferent_access.dup
          @cache = cache
          # setup a default formatter for unknown v2 annotation types (i.e. all the v1 tasks)
          @default_formatter = default_formatter || Formatter::Csv::AnnotationForCsv.new(classification, annotation, cache)
          @workflow_information = WorkflowInformation.new(cache, classification.workflow, classification.workflow_version)
          @task_info = workflow_information.task(current_annotation['task'])
        end

        def to_h
          case task_info['type']
          when 'dropdown'
            DropdownAnnotation.new(task_info, current_annotation, workflow_information).format
          else
            # use the default formatter (v1) for non v2 specific task types
            # as time goes on behaviour will eventually move from default formatter
            # to above in order to handle the newer v2 specific annotation formats
            default_formatter.to_h
          end
        end
      end
    end
  end
end
