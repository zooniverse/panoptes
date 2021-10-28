class Api::V1::SubjectSetsController < Api::ApiController
  include JsonApiController::PunditPolicy
  include FilterByMetadata
  include MediumResponse

  require_authentication %i[create update destroy create_classifications_export], scopes: [:project]
  resource_actions :default
  schema_type :json_schema
  prepend_before_action :require_login, only: %i[create update destroy create_classifications_export]

  IMPORT_COLUMNS = %w(subject_set_id subject_id random).freeze

  def create
    super do |subject_set|
      notify_subject_selector(subject_set)
      reset_subject_counts(subject_set.id)
    end
  end

  def update
    super do |subject_set|
      notify_subject_selector(subject_set)
      reset_subject_counts(subject_set.id)
    end
  end

  def update_links
    super do |subject_set|
      notify_subject_selector(subject_set)
      reset_subject_counts(subject_set.id)

      subject_set.workflow_ids.each do |workflow_id|
        UnfinishWorkflowWorker.perform_async(workflow_id)
        # recalculate the set's completeness values if we've added new subjects
        SubjectSetCompletenessWorker.perform_async(subject_set.id, workflow_id) if params.key?(:subjects)
        duration = params[:subjects].length * 4 # Pad times to prevent backlogs
        params[:subjects].each do |subject_id|
          SubjectWorkflowStatusCreateWorker.perform_in(duration.seconds*rand, subject_id, workflow_id)
        end

      end
    end
  end

  # avoid calling destroy_all on each controlled_resource
  # to optimize sets and linked relation cleanup
  def destroy
    subject_ids = Set.new
    affected_workflow_ids = Set.new
    resource_class.transaction(requires_new: true) do
      controlled_resources.each do |subject_set|
        smses = subject_set.set_member_subjects
        subject_ids |= smses.map(&:subject_id)
        remove_linked_set_member_subjects(smses)
        affected_workflow_ids |= controlled_resource.workflow_ids
        controlled_resource.subject_sets_workflows.delete_all
        controlled_resource.delete
      end
    end

    reset_workflow_retired_counts(affected_workflow_ids)
    subject_ids.each_with_index do |subject_id, index|
      SubjectRemovalWorker.perform_in(index.seconds, subject_id)
    end

    deleted_resource_response
  end

  def destroy_links
    super do |subject_set|
      notify_subject_selector(subject_set)
      reset_subject_counts(subject_set.id)
      reset_workflow_retired_counts(subject_set.workflow_ids)

      if params['link_relation'] == 'subjects'
        # recalculate the set's completeness values if # we're removing subjects
        subject_set.workflow_ids.each do |workflow_id|
          SubjectSetCompletenessWorker.perform_async(subject_set.id, workflow_id)
        end
      end
    end
  end

  def create_classifications_export
    medium = CreateClassificationsExport.with(api_user: api_user, object: controlled_resource).run!(params)
    medium_response(medium)
  end

  protected

  def notify_subject_selector(subject_set)
    if subject_set.set_member_subjects.exists?
      subject_set.workflows.each do |w|
        NotifySubjectSelectorOfChangeWorker.perform_async(w.id)
      end
    end
  end

  def build_resource_for_create(create_params)
    super do |_, link_params|
      if collection_id = link_params.delete("collection")
        if collection = Pundit.policy!(api_user, Collection).scope_for(:show).where(id: collection_id).first
          link_params["subjects"] = collection.subjects
        else
          raise ActiveRecord::RecordNotFound, "No Record Found for Collection with id: #{collection_id}"
        end
      end
    end
  end

  def add_relation(resource, relation, value)
    if relation == :subjects && value.is_a?(Array)
      #ids is returning duplicates even though the AR Relations were uniq
      subject_ids_to_link = new_items(resource, relation, value).distinct.ids
      unless Subject.where(id: subject_ids_to_link).count == value.count
        raise BadLinkParams.new("Error: check the subject set and all the subjects exist.")
      end
      new_sms_values = subject_ids_to_link.map do |subject_id|
        [ resource.id, subject_id, rand ]
      end

      result = SetMemberSubject.import IMPORT_COLUMNS, new_sms_values, validate: false
      SubjectMetadataWorker.perform_async(result.ids)
      result
    else
      super
    end
  end

  def destroy_relation(resource, relation, value)
    if relation == :subjects
      linked_sms_ids = value.split(',').map(&:to_i)
      set_member_subjects = resource.set_member_subjects.where(subject_id: linked_sms_ids)
      remove_linked_set_member_subjects(set_member_subjects)
    else
      super
    end
  end

  private

  def remove_linked_set_member_subjects(set_member_subjects)
    set_member_subjects.delete_all
  end

  def reset_workflow_retired_counts(workflow_ids)
    workflow_ids.each do |w_id|
      WorkflowRetiredCountWorker.perform_async(w_id)
    end
  end

  def reset_subject_counts(set_id)
    SubjectSetSubjectCounterWorker.perform_async(set_id)
  end
end
