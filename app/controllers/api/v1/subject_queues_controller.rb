class Api::V1::SubjectQueuesController < Api::ApiController
  doorkeeper_for :update, :destroy, :create, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, links: [:user, :workflow, subjects: []]
  allowed_params :update, links: [subjects: []]

  protected

  def resource_name
    "user_subject_queue"
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
