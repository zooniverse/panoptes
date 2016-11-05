module SubjectSets
  class RelationManager < Generic::RelationManager
    IMPORT_COLUMNS = %w(subject_set_id subject_id random)

    def add_relation(resource, relation, value)
      if relation == :subjects && value.is_a?(Array)
        #ids is returning duplicates even though the AR Relations were uniq
        subject_ids_to_link = new_items(resource, relation, value).distinct.ids
        unless Subject.where(id: subject_ids_to_link).count == value.count
          raise JsonApiController::BadLinkParams.new("Error: check the subject set and all the subjects exist.")
        end
        new_sms_values = subject_ids_to_link.map do |subject_id|
          [ resource.id, subject_id, rand ]
        end
        SetMemberSubject.import IMPORT_COLUMNS, new_sms_values, validate: false
      else
        super
      end
    end

    def destroy_relation(resource, relation, value)
      if relation == :subjects
        linked_sms_ids = value.split(',').map(&:to_i)
        set_member_subjects = resource.set_member_subjects.where(subject_id: linked_sms_ids)
        remove_linked_set_member_subjects(set_member_subjects)
        reset_subject_set_workflow_counts(resource.id)
      else
        super
      end
    end

    private

    def reset_subject_set_workflow_counts(subject_set_id)
      set_workflow_ids = Workflow
                           .joins(:subject_sets)
                           .where(subject_sets: {id: subject_set_id})
                           .select(:id)
                           .distinct
                           .pluck(:id)
      set_workflow_ids.each do |w_id|
        WorkflowRetiredCountWorker.perform_async(w_id)
      end
    end

    def reset_subject_counts(set_id)
      SubjectSetSubjectCounterWorker.perform_async(set_id)
    end

    def remove_linked_set_member_subjects(set_member_subjects)
      set_member_subjects.delete_all
    end
  end
end
