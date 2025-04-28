class UserProjectPreferenceSerializer
  include Serialization::PanoptesRestpack

  can_include :user, :project
  can_sort_by :updated_at, :display_name
  can_filter_by :non_null_activity_count

  CACHE_MINS = (ENV["UPP_ACTIVITY_COUNT_CACHE_MINS"] || 5).freeze

  def self.key
    "project_preferences"
  end

  def self.page(params = {}, scope = nil, context = {})
    page_with_options NonCustomScopeFilterOptions.new(self, params, scope, context)
  end

  def self.page_with_options(options)
    puts "MDY114 HITS OPTIONS NOW"
    puts options.inspect

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

  class NonCustomScopeFilterOptions < RestPack::Serializer::Options
    CUSTOM_SCOPE_FILTERS = %i(non_null_activity_count).freeze

    def scope_with_filters
      scope_filter = {}

      non_custom_filters = @filters.except(*CUSTOM_SCOPE_FILTERS)
      non_custom_filters.keys.each do |filter|
        value = query_to_array(@filters[filter])
        scope_filter[filter] = value
      end
      @scope.where(scope_filter)


      if @filters.key?(:non_null_activity_count)
        filtered_scope = @scope.where(scope_filter)
        non_null_activity_count_upp_ids = filtered_scope.filter { |upp| !count_activity(upp).nil? && count_activity(upp) > 0 }.map(&:id)

        @scope.where(id: non_null_activity_count_upp_ids)
      end
    end

    private

    def count_activity(upp)
      if count = upp.summated_activity_count
        count
      elsif !project_workflows_ids(upp).empty?
        UserSeenSubject.count_user_activity(upp.user_id, project_workflows_ids(upp))
      end
    end

    def project_workflows_ids(upp)
      Workflow.where(project_id: upp.project_id).pluck(:id)
    end

    # def perform_cached_lookup(method_to_send, upp)
    #   cache_key = "#{upp.class}/#{upp.id}/#{method_to_send}"
    #   Rails.cache.fetch(cache_key, expires_in: CACHE_MINS.minutes) do
    #     send method_to_send
    #   end
    # end
  end
end
