module Workflows
  class RelationManager < Generic::RelationManager
    attr_reader :resource_class, :api_user

    def initialize(resource_class, api_user)
      @resource_class = resource_class
      @api_user = api_user
    end

    def add_relation(resource, relation, value)
      if relation == :retired_subjects && value.is_a?(Array)
        resource.save!
        value.each {|id| resource.retire_subject(id) }
        resource.reload
      else
        super
      end
    end

    protected

    def new_items(resource, relation, value)
      case relation
      when :retired_subjects, 'retired_subjects'
        resource.save!
        value.flat_map {|id| resource.retire_subject(id) }
        resource.reload
      when :subject_sets, 'subject_sets'
        items = construct_new_items(super(resource, relation, value), resource.project_id)
        if items.any? { |item| item.is_a?(SubjectSet) }
          items
        else
          items.first
        end
      else
        super
      end
    end

    def construct_new_items(item_scope, workflow_project_id)
      Array.wrap(item_scope).map do |item|
        if item.is_a?(SubjectSet) && !item.belongs_to_project?(workflow_project_id)
          SubjectSetCopier.new(item, workflow_project_id).duplicate_subject_set_and_subjects
        else
          item
        end
      end
    end

    def assoc_class(relation)
      case relation
      when :retired_subjects, "retired_subjects"
        SubjectWorkflowStatus
      else
        super
      end
    end
  end
end
