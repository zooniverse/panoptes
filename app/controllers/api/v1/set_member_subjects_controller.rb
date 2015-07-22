class Api::V1::SetMemberSubjectsController < Api::ApiController
  doorkeeper_for :create, :update, :destroy, scopes: [:project]
  resource_actions :default
  schema_type :strong_params

  allowed_params :create, :priority, links: [:subject, :subject_set, retired_workflows: []]
  allowed_params :update, :priority, links: [retired_workflows: []]

  def create
    super { |set_member_subject| set_member_subject.retired_subject_workflow_counts.each(&:retire!) }
  end

  def update
    super { |set_member_subject| set_member_subject.retired_subject_workflow_counts.each(&:retire!) }
  end

  def update_links
    super { |set_member_subject| set_member_subject.retired_subject_workflow_counts.each(&:retire!) }
  end
end
