# frozen_string_literal: true

module Workflows
  class UnretireSubjects < Operation
    validates :workflow_id, presence: true

    integer :workflow_id
    integer :subject_id, default: nil
    array :subject_ids, default: [] do
      integer
    end

    def execute
      return if cached_subject_ids.empty?

      UnretireSubjectWorker.perform_async(workflow_id, cached_subject_ids)
    end

    def cached_subject_ids
      @cached_subject_ids ||= Array.wrap(@subject_ids) | Array.wrap(@subject_id)
    end
  end
end
