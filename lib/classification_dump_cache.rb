class ClassificationDumpCache
  def initialize
    @workflows = {}
    @workflow_contents = {}
    @subjects = {}
    @subject_workflow_counts = {}
    @secure_ip_lookup = {}
  end

  def reset_subjects(subjects)
    @subjects = subjects.map {|subject| [subject.id, subject] }.to_h
  end

  def reset_subject_workflow_counts(subject_workflow_counts)
    @subject_workflow_counts = subject_workflow_counts.group_by(&:subject_id)
  end

  def subject(subject_id)
    @subjects[subject_id]
  end

  def retired?(subject_id, workflow_id)
    (@subject_workflow_counts[subject_id] || []).find {|swc| swc.workflow_id == workflow_id }
  end

  def workflow_at_version(workflow_id, version)
    @workflows[workflow_id] ||= {}
    @workflows[workflow_id][version] ||= begin
      workflow = Workflow.find(workflow_id)
      old_version = workflow.versions[version].try(:reify)
      old_version || workflow
    end
  end

  def workflow_content_at_version(workflow_content_id, version)
    @workflow_contents[workflow_content_id] ||= {}
    @workflow_contents[workflow_content_id][version] ||= begin
      workflow_content = WorkflowContent.find(workflow_content_id)
      old_version = workflow_content.versions[version].try(:reify)
      old_version || workflow_content
    end
  end

  def secure_user_ip(ip_string)
    @secure_ip_lookup[ip_string] ||= SecureRandom.hex(10)
  end
end
