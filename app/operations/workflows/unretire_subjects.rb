# frozen_string_literal: true

module Workflows
  class UnretireSubjects < Operation
    validates :workflow_id, presence: true, numericality: { greater_than: 0, only_integer: true }

    integer :workflow_id
    integer :subject_id, default: nil
    array :subject_ids, default: [] do
      integer
    end
    integer :subject_set_id, default: nil
    array :subject_set_ids, default: [] do
      integer
    end

    def execute
      return if cached_subject_ids.empty?

      UnretireSubjectWorker.perform_async(workflow_id, cached_subject_ids)
    end

    def cached_subject_ids
      cached_subject_ids ||= Array.wrap(@subject_ids) | Array.wrap(@subject_id)
      cached_subject_ids.push(*subject_set_subject_ids) unless subject_set_subject_ids.empty?
      @cached_subject_ids = cached_subject_ids
    end

    def subject_set_subject_ids
      set_ids ||= Array.wrap(@subject_set_ids) | Array.wrap(@subject_set_id)
      SetMemberSubject.where(subject_set_id: set_ids).pluck(:subject_id)
    end
  end
end
