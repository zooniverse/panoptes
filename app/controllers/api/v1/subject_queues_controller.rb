class Api::V1::SubjectQueuesController < Api::ApiController
  include JsonApiController

  doorkeeper_for :update, :destroy, :create, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, links: [:user, :workflow, set_member_subjects: []]
  allowed_params :update, links: [set_member_subjects: []]

  protected

  def resource_name
    "user_subject_queue"
  end

  def link_header(resource)
    api_subject_queue_url(resource)
  end

  def assoc_class(relation)
    if relation.to_sym == :set_member_subjects
      SetMemberSubject
    else
      super
    end
  end
end
