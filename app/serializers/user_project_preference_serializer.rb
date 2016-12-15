class UserProjectPreferenceSerializer
  include RestPack::Serializer
  attributes :id, :email_communication, :preferences, :href,
    :activity_count, :activity_count_by_workflow, :settings
  can_include :user, :project
  can_sort_by :updated_at

  ACTIVITY_COUNT_CACHE_MINS = (ENV["UPP_ACTIVITY_COUNT_CACHE_MINS"] || 5).freeze

  def self.key
    "project_preferences"
  end

  def activity_count
    if Panoptes.flipper["upp_activity_count_cache"].enabled?
      cache_key = "#{@model.class}/#{@model.id}/activity_count"
      Rails.cache.fetch(cache_key, expires_in: ACTIVITY_COUNT_CACHE_MINS.minutes) do
        _activity_count
      end
    else
      _activity_count
    end
  end

  def activity_count_by_workflow
    unless project_workflows_ids.empty?
      UserSeenSubject.activity_by_workflow(@model.user_id, project_workflows_ids)
    end
  end

  def user_project_activity
    unless project_workflows_ids.empty?
      UserSeenSubject.count_user_activity(@model.user_id, project_workflows_ids)
    end
  end

  def project_workflows_ids
    @project_workflow_ids ||= Workflow.where(project_id: @model.project_id).pluck(:id)
  end

  private

  def _activity_count
    if count = @model.summated_activity_count
      count
    else
      user_project_activity
    end
  end
end
