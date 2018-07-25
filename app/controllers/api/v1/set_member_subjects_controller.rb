class Api::V1::SetMemberSubjectsController < Api::ApiController
  require_authentication :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :priority, links: [:subject, :subject_set, retired_workflows: []]
  allowed_params :update, :priority, links: [retired_workflows: []]

  def create
    super do |sms|
      set_id = sms.subject_set_id
      update_set_counts(set_id)
      linked_workflow_ids(set_id).each do |workflow_id|
        SubjectWorkflowStatusCreateWorker.perform_async(
          sms.subject_id,
          workflow_id
        )
      end
    end
  end

  def destroy
    super
    # use the memoized non-destroyed resource ids to setup a worker
    controlled_resources.each do |sms|
      update_set_counts(sms.subject_set_id)
      SubjectRemovalWorker.perform_async(sms.subject_id)
    end
  end

  private

  def update_set_counts(set_id)
    SubjectSetSubjectCounterWorker.perform_async(set_id)
  end

  def linked_workflow_ids(set_id)
    SubjectSetsWorkflow.where(subject_set_id: set_id).pluck(:workflow_id)
  end
end
