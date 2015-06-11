class Api::V1::SubjectSetsController < Api::ApiController
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  def create
    super { |subject_set| refresh_queue(subject_set) }
  end

  def update
    super { |subject_set| refresh_queue(subject_set) }
  end

  def update_links
    super { |subject_set| refresh_queue(subject_set) }
  end

  def destroy_links
    super { |subject_set| refresh_queue(subject_set) }
  end

  protected

  def refresh_queue(subject_set)
    if subject_set.set_member_subjects.exists?
      subject_set.workflows.each do |w|
        ReloadQueueWorker.perform_async(w.id)
      end
    end
  end

  def build_resource_for_create(create_params)
    super do |_, link_params|
      if collection_id = link_params.delete("collection")
        if collection = Collection.scope_for(:show, api_user).where(id: collection_id).first
          link_params["subjects"] = collection.subjects
        else
          raise ActiveRecord::RecordNotFound, "No Record Found for Collection with id: #{collection_id}"
        end
      end
    end
  end

  def add_relation(resource, relation, value)
    if relation == :subjects && value.is_a?(Array)
      new_smsses = new_items(resource, relation, value).map do |subject|
        SetMemberSubject.new(subject_set: resource, subject: subject) do |sms|
          sms.set_random
        end
      end
      SetMemberSubject.import new_smsses
    else
      super
    end
  end
end
