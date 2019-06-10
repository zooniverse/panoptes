require "tasks_visitors/inject_strings"

class WorkflowSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :display_name, :tasks, :steps, :classifications_count, :subjects_count,
             :created_at, :updated_at, :finished_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise,
             :retirement, :retired_set_member_subjects_count, :href, :active, :mobile_friendly,
             :aggregation, :configuration, :public_gold_standard, :completeness

  can_include :project, :subject_sets, :tutorial_subject, :published_version

  media_include :attached_images, classifications_export: { include: false }

  can_filter_by :active, :mobile_friendly

  preload :subject_sets, :attached_images, :classifications_export, :published_version

  def self.paging_scope(params, scope, context)
    if params[:complete]
      # In Rails 5 convert to use ActiveModel::Type::Boolean.new.cast(value)
      complete_filter = ActiveRecord::Type::Boolean.new.type_cast_from_user(params[:complete])
      scope = if complete_filter
        scope.where(completeness: 1.0)
      else
        scope.where('completeness < 1.0')
      end
    end

    super(params, scope, context)
  end

  def version
    "#{@model.major_version}.#{content_version}"
  end

  def content_language
    @model.primary_language
  end

  def content_version
    @model.minor_version
  end

  def tasks
    TasksVisitors::InjectStrings.new(requested_version.strings).visit(requested_version.tasks)
    requested_version.tasks
  end

  def first_task
    requested_version.first_task
  end

  def requested_version
    if @context[:published]
      # The model itself is a valid duck type for a workflow version, since a
      # version is basically just a subset of a Workflow's columns.
      @model.published_version || @model
    else
      @model
    end
  end

  def retirement
    @model.retirement_with_defaults
  end
end
