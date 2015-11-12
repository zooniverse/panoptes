class ResetProjectCountersWorker
  include Sidekiq::Worker

  sidekiq_options queue: :data_high

  def perform(project_id)
    project = Project.find(project_id)

    return unless project.launch_date

    project.update_columns classifications_count: count_classifications_for_project(project),
                           classifiers_count: count_classififiers_for_project(project)

    project.workflows.find_each do |workflow|
      workflow.update_columns classifications_count: count_classifications_for_workflow(project, workflow)
      reset_subject_workflow_classification_counters!(workflow)
    end
  end

  private

  def count_classifications_for_project(project)
    project.classifications.where("created_at >= ?", project.launch_date).count
  end

  def count_classifications_for_workflow(project, workflow)
    workflow.classifications.where("created_at >= ?", project.launch_date).count
  end

  def count_classififiers_for_project(project)
    UserProjectPreference.connection.execute(<<-SQL)[0]["count"]
      SELECT COUNT(DISTINCT(upp.user_id)) count FROM user_project_preferences upp
      INNER JOIN classifications c ON c.user_id = upp.user_id
      INNER JOIN projects p ON p.id = upp.project_id
      WHERE upp.project_id = #{project.id} AND c.project_id = #{project.id} AND c.created_at >= p.launch_date;
    SQL
  end

  def reset_subject_workflow_classification_counters!(workflow)
    SubjectWorkflowCount.connection.execute <<-SQL
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
