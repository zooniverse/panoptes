class WorkflowSerializer
  include RestPack::Serializer
  attributes :id, :display_name, :tasks, :classifications_count, :subjects_count,
             :created_at, :updated_at, :first_task, :primary_language,
             :version, :content_language, :prioritized, :grouped, :pairwise

  can_include :project, :subject_sets, :tutorial_subject, :expert_subject_set

  DEFAULT_WORKFLOW_VERSION_NUM = 1

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
    return @content if @content
    languages = @context[:languages] || [@model.primary_language]
    @content = @model.content_for(languages, [:strings, :language, :id])
  end

  private

  def version_index_number(model)
    if model && last_version = model.versions.last
      last_version.id
    else
      DEFAULT_WORKFLOW_VERSION_NUM
    end
  end
end
