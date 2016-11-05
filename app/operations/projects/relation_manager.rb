module Projects
  class RelationManager < Generic::RelationManager
    def new_items(resource, relation, value)
      construct_new_items(super(resource, relation, value), resource.id)
    end

    private

    def construct_new_items(item_scope, project_id)
      Array.wrap(item_scope).map do |item|
        case item
        when Workflow
          item.dup.tap do |dup_object|
            dup_object.workflow_contents = item.workflow_contents.map(&:dup)
          end
        when SubjectSet
          if !item.belongs_to_project?(project_id)
            SubjectSetCopier.new(item, project_id).duplicate_subject_set_and_subjects
          else
            item
          end
        end
      end
    end
  end
end
