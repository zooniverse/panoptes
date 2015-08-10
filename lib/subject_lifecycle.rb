class SubjectLifecycle
  attr_reader :subject

  def initialize(subject)
    @subject = subject
  end

  def retire_for(workflow)
    return if retired?

    ActiveRecord::Base.transaction(requires_new: true) do
      SubjectWorkflowCount.by_subject_workflow(subject.id, workflow.id).find_each do |swc|
        swc.retire!
      end
    end
  end
end
