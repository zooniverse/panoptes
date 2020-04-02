class ResetProjectCountersWorker
  include Sidekiq::Worker

  sidekiq_options(
    queue: :data_high,
    lock: :until_executing,
    congestion:
      {
        interval: ENV.fetch('COUNTER_CONGESTION_OPTS_INTERVAL', 360),
        max_in_interval: ENV.fetch('COUNTER_CONGESTION_OPTS_MAX_IN_INTERVAL', 10),
        min_delay: ENV.fetch('COUNTER_CONGESTION_OPTS_MIN_DELAY', 180),
        reject_with: :reschedule,
        key: ->(project_id) { "project_id_#{project_id}_count_worker" },
        enabled: ->(_project_id, rate_limit=true) { rate_limit }
      }
  )

  def perform(project_id, rate_limit=true)
    project = Project.find(project_id)
    project.workflows.each do |workflow|
      reset_subject_workflow_classification_counters!(workflow)
      counter = WorkflowCounter.new(workflow)
      workflow.update_columns classifications_count: counter.classifications
      workflow.update_columns retired_set_member_subjects_count: counter.retired_subjects
    end

    counter = ProjectCounter.new(project)
    project.update_columns(
      classifications_count: counter.classifications,
      classifiers_count: counter.volunteers
    )
  end

  private

  def reset_subject_workflow_classification_counters!(workflow)
    SubjectWorkflowStatus.connection.execute <<-SQL
      UPDATE subject_workflow_counts swc
      SET classifications_count = sub.actual
      FROM (
        SELECT subject_workflow_counts.id, COUNT(cs.classification_id) actual FROM subject_workflow_counts
        INNER JOIN classification_subjects cs ON cs.subject_id = subject_workflow_counts.subject_id
        INNER JOIN classifications c ON c.id = cs.classification_id
        INNER JOIN projects p ON p.id = c.project_id
        WHERE subject_workflow_counts.workflow_id = #{workflow.id}
          AND c.created_at >= p.launch_date
        GROUP BY subject_workflow_counts.id
      ) as sub
      WHERE sub.id = swc.id;
    SQL
  end
end
