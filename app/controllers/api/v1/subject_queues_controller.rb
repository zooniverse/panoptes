class Api::V1::SubjectQueuesController < Api::ApiController
  require_authentication :update, :destroy, :create, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, links: [:user, :workflow, :subject_set, subjects: []]
  allowed_params :update, links: [subjects: []]

  protected

  def new_items(resource, relation, value, *args)
    case relation
    when "subjects", :subjects
      relation = SetMemberSubject.link_to_resource(resource, api_user, *args)
        .where(subject_id: value)
        .order("idx(array[#{value.join(',')}], set_member_subjects.subject_id)")

      relation_or_error(relation, true)
    else
      super
    end
  end

  def add_relation(resource, relation, value)
    if relation == :subjects && value.is_a?(Array)
      curr_ids = resource.set_member_subject_ids
      uniq_incoming_ids = value.uniq
      new_ids = new_items(resource, relation, uniq_incoming_ids).map(&:id)
      non_dup_prepend_ids = new_ids | curr_ids
      resource.set_member_subject_ids = non_dup_prepend_ids
    else
      super
    end
  end

  def assoc_class(relation)
    if relation.to_sym == :subjects
      Subject
    else
      super
    end
  end
end
