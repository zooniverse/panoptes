class WorkflowSerializer
  include RestPack::Serializer
  include FilterHasMany
  include BlankTypeSerializer

  attributes :id, :display_name, :tasks, :classifications_count, :subjects_count,
             :created_at, :updated_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise,
             :retirement, :retired_set_member_subjects_count

  can_include :project, :subject_sets, :tutorial_subject, :expert_subject_sets

  DEFAULT_WORKFLOW_VERSION_NUM = 1

  def self.links
    links = super
    ess = links.delete('workflows.expert_subject_sets')
    links['workflows.expert_subject_set'] = ess
    links
  end

  def version
    "#{version_index_number(@model)}.#{version_index_number(content)}"
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

  private

  def version_index_number(model)
    if model && last_version = model.versions.last
      last_version.index + 1
    else
      DEFAULT_WORKFLOW_VERSION_NUM
    end
  end
end
