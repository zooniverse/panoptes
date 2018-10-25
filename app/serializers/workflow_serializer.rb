require "tasks_visitors/inject_strings"
require 'model_version'

class WorkflowSerializer
  include Serialization::PanoptesRestpack
  include FilterHasMany
  include MediaLinksSerializer
  include CachedSerializer

  attributes :id, :display_name, :tasks, :classifications_count, :subjects_count,
             :created_at, :updated_at, :finished_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise,
             :retirement, :retired_set_member_subjects_count, :href, :active, :mobile_friendly,
             :aggregation, :configuration, :public_gold_standard, :completeness

  can_include :project, :subject_sets, :tutorial_subject, :workflow_versions, :published_version

  media_include :attached_images, classifications_export: { include: false }

  can_filter_by :active, :mobile_friendly

  # :workflow_contents, Note: re-add when the eager_load from translatable_resources is removed
  preload :subject_sets, :attached_images

  def version
    "#{@model.current_version_number}.#{content_version}"
  end

  def content_language
    content&.language
  end

  def content_version
    content.try(:current_version_number) || ModelVersion.default_version_num
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

  def content
    @content ||= @model.primary_content
  end

  def retirement
    @model.retirement_with_defaults
  end
end
