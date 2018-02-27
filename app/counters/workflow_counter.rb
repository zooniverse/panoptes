class WorkflowCounter

  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    query = SubjectWorkflowStatus
              .by_set(workflow.subject_sets.pluck(:id),
                      "SUM(classifications_count)")
              .where(SubjectWorkflowStatus.arel_table[:workflow_id].eq(workflow.id))
    rows = SubjectWorkflowStatus.connection.execute(query.to_sql)
    rows[0]["sum"].to_i
  end

  def retired_subjects
    query = SubjectWorkflowStatus
              .by_set(workflow.subject_sets.pluck(:id),
                      "COUNT(*)")
              .where(SubjectWorkflowStatus.arel_table[:workflow_id].eq(workflow.id))
              .where(SubjectWorkflowStatus.arel_table[:retired_at].not_eq(nil))
    rows = SubjectWorkflowStatus.connection.execute(query.to_sql)
    rows[0]["count"].to_i
  end

  private

  def launch_date
    workflow.project.launch_date
  end
end
