module Workflows
  class RetireSubjects < Operation
    set_callback :validate, :before, :rewrite_blank_reason

    validates :retirement_reason, inclusion: {
      in: SubjectWorkflowStatus.retirement_reasons.keys,
      allow_nil: true
    }
    validates :workflow_id, presence: true

    integer :workflow_id
    integer :subject_id, default: nil
    array :subject_ids, default: [] do
      integer
    end
    string :retirement_reason, default: nil

    def execute
      return if subject_ids.empty?
      RetireSubjectWorker.perform_async(workflow_id, subject_ids, retirement_reason)
    end

    def subject_ids
      @cached_subject_ids ||= Array.wrap(@subject_ids) | Array.wrap(@subject_id)
    end

    private

    def rewrite_blank_reason
      if @retirement_reason == "blank"
        @retirement_reason = "nothing_here"
      end
    end
  end
end
