class UserProjectPreferenceSerializer
  include RestPack::Serializer
  attributes :id, :email_communication, :preferences, :href, :activity_count, :activity_count_by_workflow
  can_include :user, :project
  can_sort_by :updated_at

  def self.key
    "project_preferences"
  end

  def activity_count
    if count = @model.summated_activity_count
      count
    else
      user_project_activity
    end
  end

  def activity_count_by_workflow
    UserSeenSubject.activity_by_workflow(@model.user_id, project_workflows_ids)
  end

  def user_project_activity
    UserSeenSubject.count_user_activity(@model.user_id, project_workflows_ids)
  end

  def project_workflows_ids
    Workflow.where(project_id: @model.project_id).pluck(:id)
  end
end
