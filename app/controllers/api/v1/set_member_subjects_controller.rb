class Api::V1::SetMemberSubjectsController < Api::ApiController
  include RoleControl::RoledController
  require_authentication :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :priority, links: [:subject, :subject_set, retired_workflows: []]
  allowed_params :update, :priority, links: [retired_workflows: []]

  def create
    super do |set_member_subject|
      update_set_counts(set_member_subject.subject_set_id)
    end
  end

  def destroy
    resource_class.transaction(requires_new: true) do
      set_id = controlled_resource.subject_set_id
      subject_id = controlled_resource.subject_id
      super
      update_set_counts(set_id)
      SubjectRemovalWorker.perform_async(subject_id)
    end
  end

  private

  def update_set_counts(set_id)
    SubjectSetSubjectCounterWorker.perform_async(set_id)
  end
end
