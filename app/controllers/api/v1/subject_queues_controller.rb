class Api::V1::SubjectQueuesController < Api::ApiController
  include JsonApiController

  doorkeeper_for :update, :destroy, :create, scopes: [:project]
  resource_actions :default

  allowed_params :create, links: [:user, :workflow, set_member_subjects: []]
  allowed_params :update, links: [set_member_subjects: []]

  alias_method :subject_queue, :controlled_resource

  protected

  def add_relation(relation, value)
    if relation == :set_member_subjects
      items = new_items(relation, value).map(&:id)
      subject_queue.set_member_subject_ids_will_change!
      subject_queue.set_member_subject_ids << items
      subject_queue.save!
    else
      super
    end
  end
  
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
