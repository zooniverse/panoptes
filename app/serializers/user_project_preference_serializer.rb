class UserProjectPreferenceSerializer
  include Serialization::PanoptesRestpack
  include CachedSerializer

  attributes :id, :email_communication, :preferences, :href,
    :activity_count, :activity_count_by_workflow, :settings,
    :created_at, :updated_at
  can_include :user, :project
  can_sort_by :updated_at, :display_name

  CACHE_MINS = (ENV["UPP_ACTIVITY_COUNT_CACHE_MINS"] || 5).freeze

  def self.key
    "project_preferences"
  end

  def self.page_with_options(options)
    if options.sorting.key?(:display_name)
      display_sort, other_sorts = options.sorting.partition do |field, direction|
        field.match(/display_name/)
      end.map(&:to_h)
      options.sorting = {}
      options.scope = options
        .scope
        .joins(:project)
        .order("projects.display_name #{display_sort[:display_name]}")
        .order(other_sorts)
    end
    super(options)
  end

  def activity_count
    perform_cached_lookup(:count_activity)
  end

  def activity_count_by_workflow
    perform_cached_lookup(:count_activity_by_workflow)
  end

  private

  def count_activity
    if count = @model.summated_activity_count
      count
    elsif !project_workflows_ids.empty?
      UserSeenSubject.count_user_activity(@model.user_id, project_workflows_ids)
    end
  end

  def count_activity_by_workflow
    unless project_workflows_ids.empty?
      UserSeenSubject.activity_by_workflow(@model.user_id, project_workflows_ids)
    end
  end

  def project_workflows_ids
    @project_workflow_ids ||= Workflow.where(project_id: @model.project_id).pluck(:id)
  end

  def perform_cached_lookup(method_to_send)
    cache_key = "#{@model.class}/#{@model.id}/#{method_to_send}"
    Rails.cache.fetch(cache_key, expires_in: CACHE_MINS.minutes) do
      send method_to_send
    end
  end
end
