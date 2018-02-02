class SubjectWorkflowCounter

  attr_reader :swc

  def initialize(swc)
    @swc = swc
  end

  def classifications
    experiment_name = "subject_workflow_counter_skip_gs_and_seen_before"
    CodeExperiment.run(experiment_name) do |e|
      e.run_if { Panoptes.flipper[experiment_name].enabled? }

      e.use do
        scope = Classification
          .where(workflow: swc.workflow_id)
          .joins("INNER JOIN classification_subjects cs ON cs.classification_id = classifications.id")
          .where("cs.subject_id = ?", swc.subject_id)

        count_classifications(scope)
      end

      e.try do
        scope = Classification
          .where(workflow: swc.workflow_id)
          .joins("INNER JOIN classification_subjects cs ON cs.classification_id = classifications.id")
          .where("cs.subject_id = ?", swc.subject_id)
          .where("gold_standard IS NOT TRUE")
          .where.not("metadata ? 'seen_before'")
          .complete

        count_classifications(scope)
      end

      # skip the mismatch reporting...we just want perf metrics
      e.ignore { true }
    end
  end

  private

  def count_classifications(scope)
    if launch_date = swc.project.launch_date
      scope = scope.where("classifications.created_at >= ?", launch_date)
    end
    scope.count
  end
end
