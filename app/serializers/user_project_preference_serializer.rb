class UserProjectPreferenceSerializer
  include RestPack::Serializer
  attributes :id, :email_communication, :preferences, :href, :activity_count
  can_include :user, :project

  def self.key
    "project_preferences"
  end

  def activity_count
    if !@model.legacy_count.blank?
      @model.legacy_count.values.reduce(:+)
    else
      @model.activity_count || user_project_activity
    end
  end

  def user_project_activity
    project_workflows_ids = Workflow.where(project_id: @model.project_id).pluck(:id)
    UserSeenSubject.count_user_activity(@model.user_id, project_workflows_ids)
  end
end
