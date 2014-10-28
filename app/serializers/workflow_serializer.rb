class WorkflowSerializer
  include RestPack::Serializer
  attributes :id, :name, :tasks, :classifications_count, :subjects_count, :created_at, :updated_at
  can_include :project, :subject_sets

  def tasks
    strings = @model.content_for(@context[:languages], :strings).strings
    tasks = @model.tasks.dup
    TasksVisitors::InjectStrings.new(strings).visit(tasks)
    tasks
  end
end
