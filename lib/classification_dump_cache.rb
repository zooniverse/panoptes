class ClassificationDumpCache
  def initialize
    @workflows = {}
    @subjects = {}
    @subject_workflow_statuses = {}
    @classification_to_subjects = {}
    @secure_ip_lookup = {}
  end

  def reset_subjects(subjects)
    @subjects = subjects.map {|subject| [subject.id, subject] }.to_h
  end

  def reset_subject_workflow_statuses(subject_workflow_statuses)
    @subject_workflow_statuses = subject_workflow_statuses.group_by(&:subject_id)
  end

  def reset_classification_subjects(classification_subjects)
    classification_groups = classification_subjects.group_by(&:first)
    @classification_to_subjects = classification_groups.map do |classification_id, groups|
      [ classification_id.to_i, groups.map { |ids| ids.last.to_i } ]
    end.to_h
  end

  def subject(subject_id)
    @subjects[subject_id]
  end

  def subject_ids_from_classification(classification_id)
    @classification_to_subjects[classification_id]
  end

  def retired?(subject_id, workflow_id)
    (@subject_workflow_statuses[subject_id] || []).find {|swc| swc.workflow_id == workflow_id }
  end

  def workflow_at_version(workflow, major_version, minor_version)
    @workflows[workflow.id] ||= {}
    @workflows[workflow.id][major_version] ||= {}
    @workflows[workflow.id][major_version][minor_version] ||= find_workflow_at_version(workflow, major_version, minor_version)
  end

  def secure_user_ip(ip_string)
    @secure_ip_lookup[ip_string] ||= SecureRandom.hex(10)
  end

  private

  def find_workflow_at_version(workflow, major_version, minor_version)
    workflow.workflow_versions.where("major_number >= ? AND minor_number >= ?", major_version, minor_version).order("major_number ASC, minor_number ASC").first!
  rescue ActiveRecord::RecordNotFound
    workflow.workflow_versions.order("major_number ASC, minor_number ASC").last
  end
end
