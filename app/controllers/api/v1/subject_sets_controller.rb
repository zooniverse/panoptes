class Api::V1::SubjectSetsController < Api::ApiController
  include FilterByMetadata

  require_authentication :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :json_schema

  def create
    super do |subject_set|
      refresh_queue(subject_set)
      reset_subject_counts(subject_set.id)
    end
  end

  def update
    super do |subject_set|
      refresh_queue(subject_set)
      reset_subject_counts(subject_set.id)
    end
  end

  def update_links
    super do |subject_set|
      refresh_queue(subject_set)
      reset_subject_counts(subject_set.id)
    end
  end

  def destroy
    resource_class.transaction(requires_new: true) do
      subject_ids = controlled_resource.set_member_subjects.map(&:subject_id)
      remove_linked_set_member_subjects(
        controlled_resource.set_member_subjects
      )
      reset_subject_set_workflow_counts(controlled_resource.id)
      controlled_resource.subject_sets_workflows.delete_all
      #avoid optimisitc locking errors
      controlled_resource.reload

      super

      subject_ids.each do |subject_id|
        SubjectRemovalWorker.perform_async(subject_id)
      end
    end
  end

  def destroy_links
    super do |subject_set|
      refresh_queue(subject_set)
      reset_subject_counts(subject_set.id)
    end
  end

  protected

  def refresh_queue(subject_set)
    if subject_set.set_member_subjects.exists?
      subject_set.workflows.each do |w|
        if Panoptes.use_cellect?(w)
          ReloadCellectWorker.perform_async(w.id)
        end
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

  private

  def remove_linked_set_member_subjects(set_member_subjects)
    set_member_subjects.delete_all
  end

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

  def relation_manager
    super(SubjectSets::RelationManager)
  end
end
