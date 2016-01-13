require "tasks_visitors/inject_strings"
require 'model_version'

class WorkflowSerializer
  include RestPack::Serializer
  include FilterHasMany
  include MediaLinksSerializer

  attributes :id, :display_name, :tasks, :classifications_count, :subjects_count,
             :created_at, :updated_at, :finished_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise,
             :retirement, :retired_set_member_subjects_count, :href, :active,
             :aggregation, :configuration, :public_gold_standard, :completeness

  can_include :project, :subject_sets, :tutorial_subject, :expert_subject_sets

  can_filter_by :active

  media_include :attached_images

  def self.links
    links = super
    ess = links.delete('workflows.expert_subject_sets')
    links['workflows.expert_subject_set'] = ess
    links
  end

  def version
    "#{@model.current_version_number}.#{content_version}"
  end

  def content_language
    content.language if content
  end

  def content_version
    content.try(:current_version_number) || ModelVersion.default_version_num
  end

  def tasks
    if content
      tasks = @model.tasks.dup
      TasksVisitors::InjectStrings.new(content.strings).visit(tasks)
      tasks
    else
      {}
    end
  end

  def content
    @content ||= @model.content_for(@context[:languages])
  end

  def retirement
    @model.retirement_with_defaults
  end
end
