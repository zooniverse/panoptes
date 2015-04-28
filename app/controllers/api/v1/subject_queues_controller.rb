class Api::V1::SubjectQueuesController < Api::ApiController
  doorkeeper_for :update, :destroy, :create, scopes: [:project]
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
      objects = relation.to_a

      objects_or_error(objects, :set_member_subjects, true)
    else
      super
    end
  end

  def resource_name
    "subject_queue"
  end

  def link_header(resource)
    api_subject_queue_url(resource)
  end

  def assoc_class(relation)
    if relation.to_sym == :subjects
      Subject
    else
      super
    end
  end
end
