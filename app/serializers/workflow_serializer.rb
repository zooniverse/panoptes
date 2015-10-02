class WorkflowSerializer
  include RestPack::Serializer
  include FilterHasMany
  include MediaLinksSerializer

  attributes :id, :display_name, :tasks, :classifications_count, :subjects_count,
             :created_at, :updated_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise,
             :retirement, :retired_set_member_subjects_count, :href, :active,
             :aggregation

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
    "#{ModelVersion.version_number(@model)}.#{ModelVersion.version_number(content)}"
  end

  def content_language
    content.language if content
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
    retire_criteria = @model.retirement
    if retire_criteria.blank?
      {
        criteria: Workflow::DEFAULT_CRITERIA,
        options: Workflow::DEFAULT_OPTS
      }
    else
      retire_criteria
    end
  end
end
