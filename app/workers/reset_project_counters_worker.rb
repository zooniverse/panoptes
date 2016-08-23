class ResetProjectCountersWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high,
    congestion: Panoptes::CongestionControlConfig.
      counter_worker.congestion_opts.merge({
        reject_with: :reschedule,
        key: ->(project_id) {
          "project_id_#{ project_id }_count_worker"
        },
        enabled: ->(project_id, rate_limit=true) { rate_limit }
      })

  def perform(project_id, rate_limit=true)
    project = Project.find(project_id)
    counter = ProjectCounter.new(project)

    project.update_columns(
      classifications_count: counter.classifications,
      classifiers_count: counter.volunteers
    )

    project.workflows.find_each do |workflow|
      workflow.update_columns classifications_count: count_classifications_for_workflow(project, workflow)
      reset_subject_workflow_classification_counters!(workflow)
    end
  end

  private

  def count_classifications_for_workflow(project, workflow)
    workflow.classifications.where("created_at >= ?", project.launch_date).count
  end

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
