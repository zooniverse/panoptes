class SubjectDumpCache
  def initialize
    reset!
  end

  def reset!
    @sws_by_subject_id = {}
    @ssw_by_set_id = {}
  end

  # Preload and cache all data needed for a batch of subjects
  def reset_for_batch(subjects, project_workflow_ids)
    reset!

    subject_ids = subjects.map(&:id)

    if subject_ids.any? && project_workflow_ids.any?
      sws_records = SubjectWorkflowStatus
        .where(subject_id: subject_ids, workflow_id: project_workflow_ids)
        .load

      @sws_by_subject_id = sws_records
        .group_by(&:subject_id)
        .transform_values { |arr| arr.index_by(&:workflow_id) }
    end

    # Prefetch SubjectSetsWorkflow for all set ids present in the batch
    set_ids = subjects.flat_map { |s| s.subject_set_ids.presence || [] }.uniq
    if set_ids.any? && project_workflow_ids.any?
      ssw_records = SubjectSetsWorkflow
        .where(workflow_id: project_workflow_ids, subject_set_id: set_ids)
        .load

      @ssw_by_set_id = ssw_records.group_by(&:subject_set_id)
    end
  end

  def statuses_for_subject(subject_id)
    @sws_by_subject_id[subject_id] || {}
  end

  def subject_set_workflows_for_set(set_id)
    @ssw_by_set_id[set_id]
  end

  def grouped_subject_set_workflows
    @ssw_by_set_id
  end
end

