class Api::V1::SubjectQueuesController < Api::ApiController
  require_authentication :update, :destroy, :create, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, links: [:user, :workflow, :subject_set, subjects: []]
  allowed_params :update, links: [subjects: []]

  protected

  def relation_manager
    super(SubjectQueues::RelationManager)
  end
end
