class WorkflowCounter

  attr_reader :workflow

  def initialize(workflow)
    @workflow = workflow
  end

  def classifications
    sws_query("sum") do |query|
      query.select("SUM(classifications_count)")
    end
  end

  def retired_subjects
    sws_query("count") do |query|
      query
      .where(SubjectWorkflowStatus.arel_table[:retired_at].not_eq(nil))
      .select("COUNT(*)")
    end
  end

  private

  def launch_date
    workflow.project.launch_date
  end

  # this is an optimized query to access the subject_id index on this table.
  # It uses an IN query with a CTE to create a subselect to access
  # the subject_id index as simple Joins do not use the index on this table
  # E.g
  # WITH sws_by_set AS (
  #   SELECT set_member_subjects.subject_id
  #   FROM set_member_subjects
  #   WHERE set_member_subjects.subject_set_id = 1
  # )
  # SELECT SUM(classifications_count)
  # FROM subject_workflow_counts
  # WHERE subject_workflow_counts.subject_id
  # IN (SELECT subject_id FROM sws_by_set)
  def sws_query(select_field)
    query = SubjectWorkflowStatus
      .where(sws_by_set_select)
      .where(
        SubjectWorkflowStatus.arel_table[:workflow_id].eq(workflow.id)
      )

    # yield to construct the specific select clause
    query = yield(query)

    cte = sws_by_set_cte(workflow.subject_sets.pluck(:id))
    query = query.with(cte)

    rows = SubjectWorkflowStatus.connection.execute(query.to_sql)
    rows.first[select_field].to_i
  end

  # create the CTE for reuse, e.g.
  # sws_by_set AS (
  #   SELECT set_member_subjects.subject_id
  #   FROM set_member_subjects
  #   WHERE set_member_subjects.subject_set_id = 1
  # )
  def sws_by_set_cte(subject_set_ids)
    cte_table = Arel::Table.new(:sws_by_set)
    smses_arel = SetMemberSubject.arel_table
    composed_cte = Arel::Nodes::As.new(
      cte_table,
      smses_arel.where(
        smses_arel[:subject_set_id].in(subject_set_ids)
      ).project(smses_arel[:subject_id])
    )
  end

  # create the where in clause matching the select from CTE, e.g.
  # subject_workflow_counts.subject_id IN (SELECT subject_id FROM sws_by_set)
  def sws_by_set_select
    cte_table = Arel::Table.new(:sws_by_set)
    select_manager = Arel::SelectManager.new(cte_table.engine)
    select_manager.project(:subject_id)
    select_manager.from("sws_by_set")
    SubjectWorkflowStatus.arel_table[:subject_id].in(select_manager)
  end
end
