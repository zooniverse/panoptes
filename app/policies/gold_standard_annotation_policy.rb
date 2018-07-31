class GoldStandardAnnotationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      return scope.all if user.is_admin?

      public_workflows = Workflow.where("public_gold_standard IS TRUE")
      public_workflow_ids = public_workflows.select(:id)

      FilterByProjectId.whitelist_exportable_projects(scope.where(workflow_id: public_workflow_ids).order(id: :asc))
    end
  end

  scope :index, with: Scope
end
